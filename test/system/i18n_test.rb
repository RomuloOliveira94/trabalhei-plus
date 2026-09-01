require "application_system_test_case"

# Smoke test: critical pages render the expected pt-BR strings (SPEC §10 Q2 —
# pt-BR is the only UI locale; en.yml stays as the fallback).
class I18nTest < ApplicationSystemTestCase
  test "guest home page renders pt-BR strings" do
    visit root_path

    assert_text "Controle suas horas extras"
    assert_text "Entrar"
    assert_text "Criar conta"
  end

  test "sign in page renders pt-BR strings" do
    visit new_user_session_path

    assert_text "Login"
    assert_text "E-mail"
    assert_text "Senha"
  end

  test "overtime index renders pt-BR strings" do
    sign_in users(:one)
    visit overtimes_path

    assert_text "Minhas horas extras"
    assert_text "Total de horas no período"
    assert_text "Nova hora extra"
    assert_button "Exportar PDF"
    assert_button "Exportar Excel"
    assert_button "Filtrar"
    # Table headers render uppercase via CSS text-transform.
    assert_text "DATA"
    assert_text "DURAÇÃO"
  end

  test "new overtime page renders pt-BR strings" do
    sign_in users(:one)
    visit new_overtime_path

    assert_text "Nova hora extra"
    assert_button "Salvar"
    assert_text "Cancelar"
  end

  # Direct hits to /404 and /500 are served by the static fallback pages in
  # public/ (they also cover pre-boot failures). The dynamic ErrorsController
  # pages are exercised by the integration suite (see errors_test.rb).
  test "static 404 page renders pt-BR message" do
    sign_in users(:one)
    visit "/404"

    assert_text "A página que você procura não existe"
  end

  test "static 500 page renders pt-BR message" do
    sign_in users(:one)
    visit "/500"

    assert_text "Desculpe, algo deu errado"
  end
end
