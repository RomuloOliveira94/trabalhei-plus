require "application_system_test_case"

class DeleteModalTest < ApplicationSystemTestCase
  test "delete opens the modal; confirming removes the row" do
    sign_in users(:one)
    visit overtimes_path

    find("button[aria-label='Apagar']", match: :first).click

    assert_selector "dialog[open]"
    assert_text "Excluir hora extra"
    assert_text "Apagar esta hora extra?"

    within("dialog") { click_button "Excluir" }

    assert_text "Hora extra apagada com sucesso."
    assert_no_text "Fechamento do relatório mensal"
  end

  test "cancel closes the modal and keeps the row" do
    sign_in users(:one)
    visit overtimes_path

    find("button[aria-label='Apagar']", match: :first).click
    assert_selector "dialog[open]"

    within("dialog") { click_button "Cancelar" }

    assert_no_selector "dialog[open]"
    assert_text "Fechamento do relatório mensal"
  end

  test "Escape closes the modal without deleting" do
    sign_in users(:one)
    visit overtimes_path

    find("button[aria-label='Apagar']", match: :first).click
    assert_selector "dialog[open]"

    page.send_keys(:escape)

    assert_no_selector "dialog[open]"
    assert_text "Fechamento do relatório mensal"
  end
end
