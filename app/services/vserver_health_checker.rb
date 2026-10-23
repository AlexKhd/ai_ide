require "net/http"
require "socket"
require "timeout"
include FileHelper

class VserverHealthChecker
  def initialize(vserver)
    @vserver = vserver
    file_append('vps_check', "-------- Starting check vps: #{vserver.inspect}", 1.megabytes, clear: true)
  end

  def call
    server_status = check_server
    app_status = check_app

    @vserver.update!(
      server_status: server_status,
      app_status: app_status,
      last_checked_at: Time.current
    )
  end

  private

  def check_server
    uri = URI.parse(@vserver.host)
    file_append('vps_check', "check VPS by address: #{uri.inspect}", 1.megabytes)

    Socket.tcp(
      uri.host,
      uri.port,
      connect_timeout: 3
    ) do
      return "online"
    end
  rescue SocketError, SystemCallError, IOError, Timeout::Error
    "offline"
  end

  def check_app
    uri = URI.join(
      @vserver.host.chomp("/") + "/",
      @vserver.healthcheck.delete_prefix("/")
    )

    file_append('vps_check', "check APP by address: #{uri.inspect}", 1.megabytes)

    return "unhealthy" unless %w[http https].include?(uri.scheme)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.open_timeout = 3
    http.read_timeout = 3

    file_append('vps_check', "check APP by address: #{http.inspect}", 1.megabytes)

    response = http.get(uri.request_uri)

    response.is_a?(Net::HTTPSuccess) ? "healthy" : "unhealthy"
  rescue StandardError
    "unhealthy"
  end
end
