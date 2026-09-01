require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include Devise::Test::IntegrationHelpers
  include ExportTestHelpers

  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  # The CRUD modal loads the form into a Turbo Frame; the frame only carries
  # the `complete` attribute once the async render finished. Tests must wait
  # for it before interacting, otherwise fill_in can race the render and
  # append to the prefilled value.
  def wait_for_crud_modal_form
    assert_selector "dialog[open]"
    assert_selector "turbo-frame#overtime_form[complete]"
    assert_selector "dialog[open] form"
  end

  # Tests that resize the window (mobile/desktop breakpoint checks) leak the
  # size to the next test in the same browser session. Restore the default so
  # desktop assertions in later tests are not affected.
  teardown do
    page.current_window.resize_to(1400, 1400)
  end
end
