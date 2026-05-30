require "test_helper"
require "capybara/cuprite"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  #driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]
  driven_by :cuprite

  setup do
    Capybara.current_driver = :cuprite
  end

  teardown do
    # Take screenshot only on failure
    if failed?
      next # using internal screenshots now
      p "--- creating screenshot on failed test for #{self.name}........"
      screenshot_name = "failure_#{Time.current.strftime('%Y%m%d_%H%M%S')}_#{self.name}.png"
      page.save_screenshot("tmp/screenshots/#{screenshot_name}")
      puts "\n Screenshot saved: tmp/screenshots/#{screenshot_name}"
    end
  end

  private

  def failed?
    !passed?
  end
end
