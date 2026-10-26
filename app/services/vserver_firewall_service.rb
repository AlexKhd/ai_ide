# app/services/vserver_firewall_service.rb

require "net/ssh"
require "base64"
require "uri"

class VserverFirewallService
  HELPER_PATH = "/usr/local/sbin/rails-vps-firewall"

  HELPER_CONTENT = <<~'BASH'
    #!/usr/bin/env bash
    set -euo pipefail

    case "${1:-}" in
      status)
        echo "=== UFW STATUS ==="
        ufw status verbose
        echo "=== UFW RULES ==="
        ufw status numbered
        ;;

      apply-baseline)
        # Preserve SSH access before enabling the firewall.
        ufw allow 22/tcp
        ufw allow 80/tcp
        ufw allow 443/tcp

        ufw default deny incoming
        ufw default allow outgoing

        ufw --force enable

        echo "=== UFW STATUS ==="
        ufw status verbose
        echo "=== UFW RULES ==="
        ufw status numbered
        ;;

      *)
        echo "Unsupported operation" >&2
        exit 2
        ;;
    esac
  BASH

  Result = Data.define(:success?, :data, :message)

  def initialize(vserver)
    @vserver = vserver
  end

  def status
    with_ssh do |ssh|
      installed = command(ssh, "command -v ufw >/dev/null 2>&1")

      unless installed.success?
        return result(
          false,
          { ufw_installed: false },
          "UFW is not installed."
        )
      end

      helper_installed = command(
        ssh,
        "#{root_prefix} test -x #{HELPER_PATH}"
      )

      ufw_result = command(
        ssh,
        "#{root_prefix} ufw status verbose"
      )

      rules_result = command(
        ssh,
        "#{root_prefix} ufw status numbered"
      )

      unless ufw_result.success?
        return result(
          false,
          { ufw_installed: true },
          "Unable to retrieve UFW status."
        )
      end

      output = ufw_result.stdout
      rules = rules_result.stdout

      active = output.match?(/^Status:\s+active\b/i)

      data = {
        ssh_connected: true,
        ufw_installed: true,
        ufw_active: active,
        helper_installed: helper_installed.success?,
        ssh_rule: allowed_rule?(rules, 22),
        http_rule: allowed_rule?(rules, 80),
        https_rule: allowed_rule?(rules, 443),
        raw_status: output,
        raw_rules: rules
      }

      result(true, data, "Firewall status retrieved.")
    end
  rescue StandardError => e
    Rails.logger.error(
      "Firewall status failed for Vserver ##{vserver.id}: " \
      "#{e.class}: #{e.message}\n" \
      "#{e.backtrace&.first(10)&.join("\n")}"
    )

    result(
      false,
      { ssh_connected: false },
      "Unable to connect to the VPS or inspect its firewall."
    )
  end

  def install_helper
    with_ssh do |ssh|
      # Check for UFW first.
      ufw = command(ssh, "command -v ufw >/dev/null 2>&1")

      unless ufw.success?
        return result(
          false,
          {},
          "UFW is not installed. Install it before continuing."
        )
      end

      encoded = Base64.strict_encode64(HELPER_CONTENT)

      # Only static, application-defined content is installed.
      install_command = [
        "printf '%s' '#{encoded}'",
        "| base64 -d",
        "| #{root_prefix} install -o root -g root -m 750 /dev/stdin #{HELPER_PATH}"
      ].join(" ")

      installed = command(ssh, install_command)

      unless installed.success?
        return result(
          false,
          {},
          "Could not install the firewall helper. Check root/sudo permissions."
        )
      end

      # Verify that the installed helper is executable.
      verified = command(
        ssh,
        "#{root_prefix} test -x #{HELPER_PATH}"
      )

      result(
        verified.success?,
        { helper_installed: verified.success? },
        verified.success? ? "Firewall helper installed." : "Helper verification failed."
      )
    end
  rescue StandardError => e
    Rails.logger.error(
      "Firewall helper installation failed for Vserver ##{@vserver.id}: #{e.class}"
    )

    result(false, {}, "Unable to install the firewall helper.")
  end

  def apply_baseline
    with_ssh do |ssh|
      helper = command(
        ssh,
        "#{root_prefix} test -x #{HELPER_PATH}"
      )

      unless helper.success?
        return result(
          false,
          {},
          "Install the firewall helper before applying configuration."
        )
      end

      applied = command(
        ssh,
        "#{root_prefix} #{HELPER_PATH} apply-baseline"
      )

      unless applied.success?
        return result(
          false,
          {},
          "Firewall configuration failed. Check the VPS and its firewall."
        )
      end

      result(
        true,
        { output: applied.stdout },
        "Firewall baseline applied."
      )
    end
  rescue StandardError => e
    Rails.logger.error(
      "Firewall configuration failed for Vserver ##{@vserver.id}: #{e.class}"
    )

    result(false, {}, "Unable to apply firewall configuration.")
  end

  private

  attr_reader :vserver

  def with_ssh
    credentials = Rails.application.credentials.vps

    key_path = File.expand_path(credentials.ssh_key_path)
    passphrase = credentials.ssh_key_passphrase

    raise "VPS SSH key file not found: #{key_path}" unless File.file?(key_path)
    raise "VPS SSH key file is not readable" unless File.readable?(key_path)

    Net::SSH.start(
      ssh_host,
      vserver.username,
      port: vserver.ssh_port || 22,
      keys: [key_path],
      passphrase: passphrase,
      non_interactive: true,
      verify_host_key: :always,
      timeout: 10
    ) do |ssh|
      yield ssh
    end
  end

  def root_prefix
    vserver.username == "root" ? "" : "sudo -n"
  end

  def command(ssh, cmd)
    stdout = +""
    stderr = +""
    exit_code = nil

    channel = ssh.open_channel do |ch|
      ch.exec(cmd) do |_channel, success|
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

  def allowed_rule?(rules, port)
    rules.each_line.any? do |line|
      line.match?(/^\[\s*\d+\]\s+#{port}\/tcp\s+ALLOW\b/i)
    end
  end

  def result(success, data, message)
    Result.new(
      success?: success,
      data: data,
      message: message
    )
  end

  def ssh_host
    URI.parse(vserver.host).host || vserver.host
  end
end
