require "application_system_test_case"

class OvertimeFlowTest < ApplicationSystemTestCase
  test "index renders a table on desktop and cards on mobile" do
    sign_in users(:one)
    visit overtimes_path

    assert_selector "h1", text: "Minhas horas extras"
    # Desktop (>= md): table visible, cards hidden.
    assert_selector "table tbody tr", count: 1
    assert_selector "td", text: "Fechamento do relatório mensal"
    assert_no_selector "p.line-clamp-2", text: "Fechamento do relatório mensal"

    # Mobile (< md): cards visible, table hidden.
    page.current_window.resize_to(375, 812)
    assert_no_selector "table tbody tr"
    assert_selector "p.line-clamp-2", text: "Fechamento do relatório mensal"
  end

  test "creates, updates and deletes an overtime" do
    sign_in users(:one)
    visit overtimes_path

    # Create
    click_link "Nova hora extra"
    day = Date.current.beginning_of_month
    # datetime-local inputs must be filled with Time objects (Capybara sets
    # them via JS); raw ISO strings get mangled by Chrome's segmented widget.
    fill_in "Início", with: Time.zone.local(day.year, day.month, day.day, 20, 0, 0)
    fill_in "Fim", with: Time.zone.local(day.year, day.month, day.day, 21, 30, 0)
    fill_in "Descrição", with: "Plantão de domingo"
    click_button "Salvar"

    assert_text "Hora extra cadastrada com sucesso."
    assert_text "Plantão de domingo"
    assert_text "1,5h"

    # Update the first row (fixture, chronological order)
    find("a[aria-label='Editar']", match: :first).click
    fill_in "Descrição", with: "Fechamento do relatório mensal (revisado)"
    click_button "Salvar"

    assert_text "Hora extra atualizada com sucesso."
    assert_text "Fechamento do relatório mensal (revisado)"

    # Delete with confirmation modal
    find("button[aria-label='Apagar']", match: :first).click
    within("dialog") { click_button "Excluir" }

    assert_text "Hora extra apagada com sucesso."
    assert_no_text "Fechamento do relatório mensal (revisado)"
    assert_text "Plantão de domingo"
  end
end
