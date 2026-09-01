require "application_system_test_case"

# SPEC AC-1/AC-2/AC-3: create appends, update replaces, delete removes —
# all without a full page reload. A window-level marker survives Turbo
# navigations but is wiped by a real browser reload, so it distinguishes
# "no reload" from a full page load.
class TurboStreamCrudTest < ApplicationSystemTestCase
  test "create appends the new row without a full page reload" do
    sign_in users(:one)
    visit overtimes_path
    page.evaluate_script("window.__no_reload = true")

    click_link "Nova hora extra"
    wait_for_crud_modal_form

    day = Date.current.beginning_of_month
    fill_in "Início", with: Time.zone.local(day.year, day.month, day.day, 20, 0, 0)
    fill_in "Fim", with: Time.zone.local(day.year, day.month, day.day, 21, 30, 0)
    fill_in "Descrição", with: "Hora extra via Turbo Stream"
    click_button "Salvar"

    assert_equal true, page.evaluate_script("window.__no_reload")
    assert_match %r{/overtimes\z}, page.current_url
    assert_text "Hora extra cadastrada com sucesso."
    # Row appended to the desktop table, card to the mobile list (hidden on
    # the desktop viewport, but present in the DOM).
    assert_selector "table tbody tr", count: 2
    assert_selector "#overtimes-mobile-list #overtime_card_#{Overtime.last.id}", visible: :hidden
    # The CRUD modal closes after the stream applies.
    assert_no_selector "dialog[open]"
  end

  test "update replaces the row in place without a full page reload" do
    sign_in users(:one)
    visit overtimes_path
    page.evaluate_script("window.__no_reload = true")

    find("a[aria-label='Editar']", match: :first).click
    wait_for_crud_modal_form

    fill_in "Descrição", with: "Descrição atualizada via stream"
    click_button "Salvar"

    assert_equal true, page.evaluate_script("window.__no_reload")
    assert_match %r{/overtimes\z}, page.current_url
    assert_text "Hora extra atualizada com sucesso."
    assert_text "Descrição atualizada via stream"
    assert_no_text "Fechamento do relatório mensal"
  end

  test "create from an empty filter replaces the empty state with the list" do
    sign_in users(:one)
    # A day with no records: the index shows the empty state.
    day = Date.current.beginning_of_month + 14.days
    visit overtimes_path(q: {
      start_at_gteq: day.to_s,
      start_at_lteq: day.to_s
    })
    assert_text "Nenhuma hora extra cadastrada neste período."
    page.evaluate_script("window.__no_reload = true")

    click_link "Nova hora extra"
    wait_for_crud_modal_form
    fill_in "Início", with: Time.zone.local(day.year, day.month, day.day, 20, 0, 0)
    fill_in "Fim", with: Time.zone.local(day.year, day.month, day.day, 21, 0, 0)
    fill_in "Descrição", with: "Primeira hora extra do dia"
    click_button "Salvar"

    assert_equal true, page.evaluate_script("window.__no_reload")
    assert_no_text "Nenhuma hora extra cadastrada neste período."
    assert_text "Primeira hora extra do dia"
    assert_selector "table tbody tr", count: 1
  end

  test "delete via modal removes the row without a full page reload" do
    sign_in users(:one)
    visit overtimes_path
    page.evaluate_script("window.__no_reload = true")

    find("button[aria-label='Apagar']", match: :first).click
    within("dialog") { click_button "Excluir" }

    assert_equal true, page.evaluate_script("window.__no_reload")
    assert_match %r{/overtimes\z}, page.current_url
    assert_text "Hora extra apagada com sucesso."
    assert_no_text "Fechamento do relatório mensal"
  end
end
