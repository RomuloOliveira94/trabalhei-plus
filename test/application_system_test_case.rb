require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include Devise::Test::IntegrationHelpers
  include ExportTestHelpers

  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  # Tests that resize the window (mobile/desktop breakpoint checks) leak the
  # size to the next test in the same browser session. Restore the default so
  # desktop assertions in later tests are not affected.
  teardown do
    page.current_window.resize_to(1400, 1400)
  end
end
