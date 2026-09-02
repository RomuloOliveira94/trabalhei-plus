require "application_system_test_case"

# Post-merge polish: the "Limpar filtros" link (only while a Ransack filter is
# active) and the auto-dismissing flash messages (Stimulus timer + close X).
class FilterAndFlashTest < ApplicationSystemTestCase
  test "clear filters link appears only when a Ransack filter is active" do
    sign_in users(:one)

    visit overtimes_path
    assert_no_link "Limpar filtros"

    month = Date.current.prev_month
    visit overtimes_path(q: {
      start_at_gteq: month.beginning_of_month.to_s,
      start_at_lteq: month.end_of_month.to_s
    })
    assert_link "Limpar filtros"
  end

  test "clear filters resets to the default current-month view" do
    sign_in users(:one)
    month = Date.current.prev_month
    visit overtimes_path(q: {
      start_at_gteq: month.beginning_of_month.to_s,
      start_at_lteq: month.end_of_month.to_s
    })

    click_link "Limpar filtros"

    assert_current_path overtimes_path
    assert_no_link "Limpar filtros"
    assert_equal Date.current.beginning_of_month.to_s, find_field("q_start_at_gteq").value
    assert_equal Date.current.end_of_month.to_s, find_field("q_start_at_lteq").value
  end

  test "flash close button dismisses the message immediately" do
    sign_in users(:one)
    visit overtimes_path

    create_overtime("Flash via botão fechar")

    assert_text "Hora extra cadastrada com sucesso."
    find("button[aria-label='Fechar']").click
    assert_no_text "Hora extra cadastrada com sucesso."
  end

  test "flash auto-dismisses after the notice delay" do
    sign_in users(:one)
    visit overtimes_path

    create_overtime("Flash auto-dismiss")

    assert_text "Hora extra cadastrada com sucesso."
    # notice delay is 5s + 0.5s fade-out; wait up to 7s for the removal.
    assert page.has_no_text?("Hora extra cadastrada com sucesso.", wait: 7)
  end

  private
    def create_overtime(description)
      click_link "Nova hora extra"
      wait_for_crud_modal_form

      day = Date.current.beginning_of_month
      fill_in "Início", with: Time.zone.local(day.year, day.month, day.day, 20, 0, 0)
      fill_in "Fim", with: Time.zone.local(day.year, day.month, day.day, 21, 30, 0)
      fill_in "Descrição", with: description
      click_button "Salvar"
    end
end
