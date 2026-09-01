require "application_system_test_case"

# Phase 5 follow-up: CRUD forms open in a <dialog> modal instead of inline.
# The list stays visible behind the modal and updates via the existing Turbo
# Streams; the modal closes on success and stays open with errors on 422.
class ModalCrudTest < ApplicationSystemTestCase
  test "create opens the modal, saves and closes with the list updated" do
    sign_in users(:one)
    visit overtimes_path
    page.evaluate_script("window.__no_reload = true")

    click_link "Nova hora extra"
    wait_for_crud_modal_form
    # Focus lands on the first field once the frame finishes rendering.
    assert_selector "input#overtime_start_at:focus"

    day = Date.current.beginning_of_month
    fill_in "Início", with: Time.zone.local(day.year, day.month, day.day, 20, 0, 0)
    fill_in "Fim", with: Time.zone.local(day.year, day.month, day.day, 21, 30, 0)
    fill_in "Descrição", with: "Hora extra via modal"
    click_button "Salvar"

    assert_equal true, page.evaluate_script("window.__no_reload")
    assert_match %r{/overtimes\z}, page.current_url
    assert_no_selector "dialog[open]"
    assert_text "Hora extra cadastrada com sucesso."
    assert_text "Hora extra via modal"
  end

  test "edit opens the modal prefilled and updates the row in place" do
    sign_in users(:one)
    visit overtimes_path
    page.evaluate_script("window.__no_reload = true")

    find("a[aria-label='Editar']", match: :first).click
    wait_for_crud_modal_form
    assert_equal "Fechamento do relatório mensal", find_field("Descrição").value

    fill_in "Descrição", with: "Descrição atualizada via modal"
    click_button "Salvar"

    assert_equal true, page.evaluate_script("window.__no_reload")
    assert_no_selector "dialog[open]"
    assert_text "Hora extra atualizada com sucesso."
    assert_text "Descrição atualizada via modal"
    assert_no_text "Fechamento do relatório mensal"
  end

  test "validation errors keep the modal open with the errors visible" do
    sign_in users(:one)
    visit overtimes_path

    click_link "Nova hora extra"
    wait_for_crud_modal_form

    day = Date.current.beginning_of_month
    fill_in "Início", with: Time.zone.local(day.year, day.month, day.day, 20, 0, 0)
    fill_in "Fim", with: Time.zone.local(day.year, day.month, day.day, 18, 0, 0)
    fill_in "Descrição", with: "Intervalo invertido"
    click_button "Salvar"

    assert_selector "dialog[open]"
    assert_text "deve ser depois do início"
    assert_no_text "Hora extra cadastrada com sucesso."
  end

  test "cancel closes the modal and keeps the list unchanged" do
    sign_in users(:one)
    visit overtimes_path

    click_link "Nova hora extra"
    wait_for_crud_modal_form

    within("dialog[open]") { click_link "Cancelar" }

    assert_no_selector "dialog[open]"
    assert_text "Fechamento do relatório mensal"
  end

  test "Escape closes the modal and keeps the list unchanged" do
    sign_in users(:one)
    visit overtimes_path

    click_link "Nova hora extra"
    wait_for_crud_modal_form

    page.send_keys(:escape)

    assert_no_selector "dialog[open]"
    assert_text "Fechamento do relatório mensal"
  end

  test "focus is trapped inside the modal" do
    sign_in users(:one)
    visit overtimes_path

    find("a[aria-label='Editar']", match: :first).click
    wait_for_crud_modal_form
    assert_selector "input#overtime_start_at:focus"

    # Tab from the last focusable element wraps back to the first one
    # (the close button, which precedes the form in the dialog).
    page.execute_script("var d = document.querySelector('dialog[open]'); var f = d.querySelectorAll('button, [href], input, select, textarea, [tabindex]:not([tabindex=\"-1\"])'); f[f.length - 1].focus()")
    page.send_keys(:tab)
    assert_equal "dialog-modal-close", page.evaluate_script("document.activeElement.id")
  end
end
