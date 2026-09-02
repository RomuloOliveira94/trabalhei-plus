require "application_system_test_case"

# Post-merge polish: the "Limpar filtros" link (only while a Ransack filter is
# active) and the auto-dismissing flash messages (Stimulus timer + close X).
class FilterAndFlashTest < ApplicationSystemTestCase
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
