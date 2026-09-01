require "application_system_test_case"

# Phase 6: the new-overtime form pre-selects today's date so the user only
# adjusts the times (SPEC §3 flow step 3). Edit keeps the stored values.
class OvertimeFormDefaultTest < ApplicationSystemTestCase
  test "new overtime modal pre-fills start and end with today's date" do
    sign_in users(:one)
    visit overtimes_path

    click_link "Nova hora extra"
    wait_for_crud_modal_form

    today = Time.zone.now.strftime("%Y-%m-%d")
    within("dialog[open]") do
      start_value = find("#overtime_start_at").value
      end_value = find("#overtime_end_at").value
      assert start_value.start_with?(today), "expected start_at #{start_value} to start with #{today}"
      assert end_value.start_with?(today), "expected end_at #{end_value} to start with #{today}"
    end
  end

  test "edit form keeps the stored start and end values" do
    overtime = overtimes(:one)
    sign_in users(:one)
    visit edit_overtime_path(overtime)

    assert_equal overtime.start_at.strftime("%Y-%m-%dT%H:%M"), find("#overtime_start_at").value
    assert_equal overtime.end_at.strftime("%Y-%m-%dT%H:%M"), find("#overtime_end_at").value
  end
end
