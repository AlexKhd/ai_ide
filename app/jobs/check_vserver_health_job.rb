class CheckVserverHealthJob < ApplicationJob
  queue_as :default

  def perform(vserver)
    VserverHealthChecker.new(vserver).call
  ensure
    vserver.update!(checking: false)
  end
end
