class CheckVserverHealthJob < ApplicationJob
  queue_as :default

  def perform(vserver)
    VserverHealthChecker.new(vserver).call
  end
end
