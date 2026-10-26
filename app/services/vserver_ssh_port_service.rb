# app/services/vserver_ssh_port_service.rb

require "net/ssh"
require "base64"

class VserverSshPortService
  Result = Data.define(:success?, :data, :message)

  def initialize(vserver)
    @vserver = vserver
  end

  def inspect
    with_ssh do |ssh|
      sshd_check = execute(ssh, "sudo -n sshd -t")

      unless sshd_check.success?
        return result(
          false,
          { sshd_config_valid: false },
          "The current SSH configuration is invalid."
        )
      end

      ports_result = execute(
        ssh,
        "sudo -n sshd -T | grep '^port '"
      )

      unless ports_result.success?
        return result(
          false,
          {},
          "Unable to inspect the effective SSH ports."
        )
      end

      socket_result = execute(
        ssh,
        "systemctl is-active ssh.socket"
      )

      service_result = execute(
        ssh,
        "systemctl is-active ssh.service"
      )

      ufw_result = execute(
        ssh,
        "sudo -n ufw status"
      )

      data = {
        sshd_config_valid: true,
        configured_ports: ports_result.stdout.lines.filter_map do |line|
          match = line.match(/\Aport\s+(\d+)\s*\z/i)
          match && match[1].to_i
        end,
        ssh_socket_active: socket_result.stdout.strip == "active",
        ssh_service_active: service_result.stdout.strip == "active",
        ufw_active: ufw_result.stdout.include?("Status: active"),
        ufw_status: ufw_result.stdout
      }

      result(true, data, "SSH configuration inspected.")
    end
  rescue StandardError => e
    Rails.logger.error(
      "SSH inspection failed for Vserver ##{@vserver.id}: " \
      "#{e.class}: #{e.message}"
    )

    result(
      false,
      {},
      "Unable to inspect the VPS SSH configuration."
    )
  end

  def diagnostics
    commands = {
      ssh_config: "sudo -n grep -RniE '^[[:space:]]*(Include|Port|ListenAddress)[[:space:]]' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/ 2>/dev/null",
      socket_config: "sudo -n systemctl cat ssh.socket",
      socket_properties: "sudo -n systemctl show ssh.socket -p Listen -p FragmentPath -p DropInPaths",
      listening_ports: "sudo -n ss -ltnp",
      ssh_socket_state: "systemctl is-enabled ssh.socket"
    }

    with_ssh do |ssh|
      commands.transform_values do |cmd|
        response = execute(ssh, cmd)

        {
          success: response.success?,
          output: response.stdout,
          error: response.stderr
        }
      end
    end
  rescue StandardError => e
    Rails.logger.error(
      "SSH diagnostics failed for Vserver ##{vserver.id}: " \
      "#{e.class}: #{e.message}"
    )

    {
      error: "#{e.class}: #{e.message}"
    }
  end

  def add_port(new_port)
    new_port = Integer(new_port)

    unless new_port.between?(1024, 65_535)
      return result(
        false,
        {},
        "SSH port must be between 1024 and 65535."
      )
    end

    old_port = vserver.ssh_port

    if new_port == old_port
      return result(
        false,
        { ssh_port: old_port },
        "The requested port is already the configured SSH port."
      )
    end

    with_ssh do |ssh|
      # Confirm that the current configuration is valid.
      check = execute(ssh, "sudo -n sshd -t")

      unless check.success?
        return result(
          false,
          { ssh_port: old_port },
          "The current SSH configuration is invalid."
        )
      end

      # This implementation assumes the standard Ubuntu socket.
      socket_check = execute(
        ssh,
        "sudo -n systemctl show ssh.socket -p FragmentPath -p DropInPaths"
      )

      unless socket_check.success? &&
             socket_check.stdout.include?(
               "FragmentPath=/usr/lib/systemd/system/ssh.socket"
             ) &&
             socket_check.stdout.include?("DropInPaths=\n")
        return result(
          false,
          { ssh_port: old_port },
          "Unexpected SSH socket configuration. Inspect it before proceeding."
        )
      end

      socket_state = execute(
        ssh,
        "systemctl is-active ssh.socket"
      )

      unless socket_state.success? &&
             socket_state.stdout.strip == "active"
        return result(
          false,
          { ssh_port: old_port },
          "SSH socket activation is not active."
        )
      end

      # Refuse to overwrite an existing listener on the requested port.
      occupied = execute(
        ssh,
        "sudo -n ss -H -ltn 'sport = :#{new_port}'"
      )

      unless occupied.success?
        return result(
          false,
          { ssh_port: old_port },
          "Unable to check whether port #{new_port} is available."
        )
      end

      if occupied.stdout.present?
        return result(
          false,
          { ssh_port: old_port },
          "Port #{new_port} is already occupied."
        )
      end

      # Open the new port before changing the SSH socket.
      firewall = execute(
        ssh,
        "sudo -n ufw allow #{new_port}/tcp"
      )

      unless firewall.success?
        return result(
          false,
          { ssh_port: old_port },
          "Could not allow port #{new_port} through UFW."
        )
      end

      # Keep the existing port and add the requested port.
      config = <<~CONF
        [Socket]
        ListenStream=
        ListenStream=#{old_port}
        ListenStream=#{new_port}
      CONF

      encoded = Base64.strict_encode64(config)

      install = execute(
        ssh,
        [
          "sudo -n install -d -m 755 /etc/systemd/system/ssh.socket.d",
          "&& printf '%s' '#{encoded}' | base64 -d",
          "| sudo -n tee /etc/systemd/system/ssh.socket.d/override.conf >/dev/null",
          "&& sudo -n chmod 644 /etc/systemd/system/ssh.socket.d/override.conf"
        ].join(" ")
      )

      unless install.success?
        return result(
          false,
          { ssh_port: old_port },
          "Could not install the SSH socket override. Port #{old_port} remains configured."
        )
      end

      reload = execute(ssh, "sudo -n systemctl daemon-reload")

      unless reload.success?
        return result(
          false,
          { ssh_port: old_port },
          "Systemd reload failed. Inspect the socket configuration."
        )
      end

      restart = execute(ssh, "sudo -n systemctl restart ssh.socket")

      unless restart.success?
        return result(
          false,
          { ssh_port: old_port },
          "Could not restart ssh.socket. Inspect the service before retrying."
        )
      end

      # Check the socket's configured listeners.
      listeners = execute(
        ssh,
        "sudo -n systemctl show ssh.socket -p Listen"
      )

      unless listeners.success?
        return result(
          false,
          { ssh_port: old_port },
          "Unable to verify the SSH socket configuration."
        )
      end

      # Verify that both ports appear in the actual listening sockets.
      listening = execute(
        ssh,
        "sudo -n ss -H -ltn"
      )

      unless listening.success?
        return result(
          false,
          { ssh_port: old_port },
          "Unable to verify listening ports."
        )
      end

      listening_ports = listening.stdout.lines.filter_map do |line|
        address = line.split[3]
        address&.match(/:(\d+)\z/)&.captures&.first&.to_i
      end

      unless listening_ports.include?(old_port) &&
             listening_ports.include?(new_port)
        return result(
          false,
          {
            ssh_port: old_port,
            listening_ports: listening_ports
          },
          "The expected SSH listeners were not detected. Keep the existing session open and investigate."
        )
      end

      result(
        true,
        {
          old_port: old_port,
          new_port: new_port,
          listening_ports: listening_ports,
          ufw_rule_added: true
        },
        "SSH is listening on ports #{old_port} and #{new_port}. Test the new connection before switching Rails to it."
      )
    end
  rescue ArgumentError, TypeError
    result(false, {}, "Enter a valid TCP port number.")
  rescue StandardError => e
    Rails.logger.error(
      "SSH port change failed for Vserver ##{vserver.id}: " \
      "#{e.class}: #{e.message}"
    )

    result(
      false,
      { ssh_port: vserver.ssh_port },
      "Unable to add the SSH port. Inspect the VPS before retrying."
    )
  end

  private

  attr_reader :vserver

  def with_ssh
    credentials = Rails.application.credentials.vps

    key_path = File.expand_path(credentials.ssh_key_path)
    passphrase = credentials.ssh_key_passphrase

    raise "SSH private key not found" unless File.file?(key_path)

    Net::SSH.start(
      ssh_host,
      vserver.username,
      port: vserver.ssh_port,
      keys: [key_path],
      passphrase: passphrase,
      non_interactive: true,
      verify_host_key: :always,
      timeout: 10
    ) do |ssh|
      yield ssh
    end
  end

  def ssh_host
    require "uri"

    URI.parse(vserver.host).host || vserver.host
  end

  def execute(ssh, command)
    stdout = +""
    stderr = +""
    exit_code = nil

    channel = ssh.open_channel do |ch|
      ch.exec(command) do |_channel, success|
        raise "Remote command could not start" unless success

        ch.on_data { |_c, data| stdout << data }
        ch.on_extended_data { |_c, _type, data| stderr << data }

        ch.on_request("exit-status") do |_c, data|
          exit_code = data.read_long
        end
      end
    end

    channel.wait

    CommandResult.new(
      stdout: stdout,
      stderr: stderr,
      exit_code: exit_code
    )
  end

  CommandResult = Data.define(:stdout, :stderr, :exit_code) do
    def success?
      exit_code == 0
    end
  end

  def result(success, data, message)
    Result.new(
      success?: success,
      data: data,
      message: message
    )
  end
end
