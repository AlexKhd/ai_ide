require "net/http"
require "socket"
require "timeout"

class VserverHealthChecker
  def initialize(vserver)
    @vserver = vserver
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

    return "unhealthy" unless %w[http https].include?(uri.scheme)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.open_timeout = 3
    http.read_timeout = 3

    response = http.get(uri.request_uri)

    response.is_a?(Net::HTTPSuccess) ? "healthy" : "unhealthy"
  rescue StandardError
    "unhealthy"
  end
end
