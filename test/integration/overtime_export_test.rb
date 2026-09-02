require "test_helper"

class OvertimeExportTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "requires authentication" do
    get export_overtimes_pdf_path
    assert_redirected_to new_user_session_path

    get export_overtimes_xlsx_path
    assert_redirected_to new_user_session_path
  end

  test "export_pdf returns a PDF with the expected filename" do
    sign_in users(:one)
    get export_overtimes_pdf_path, params: {
      from: Date.current.beginning_of_month.to_s,
      to: Date.current.end_of_month.to_s
    }

    assert_response :success
    assert_equal "application/pdf", response.media_type
    assert response.body.start_with?("%PDF-")
    assert_match(/filename="horas_extras_ana-souza_/, response.headers["Content-Disposition"])

    text = pdf_text(response.body)
    assert_match "Usuário: Ana Souza", text
    assert_no_match /ana@example\.com/, text
  end

  test "export_xlsx returns an xlsx with the expected filename" do
    sign_in users(:one)
    get export_overtimes_xlsx_path, params: {
      from: Date.current.beginning_of_month.to_s,
      to: Date.current.end_of_month.to_s
    }

    assert_response :success
    assert_equal "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", response.media_type
    assert response.body.start_with?("PK")
    assert_match(/filename="horas_extras_ana-souza_/, response.headers["Content-Disposition"])

    text = xlsx_text(response.body)
    assert_includes text, "Usuário"
    assert_includes text, "Ana Souza"
    assert_not_includes text, "ana@example.com"
  end

  test "export filename reflects the requested period" do
    sign_in users(:one)
    month = Date.current.prev_month
    get export_overtimes_pdf_path, params: {
      from: month.beginning_of_month.to_s,
      to: month.end_of_month.to_s
    }

    assert_response :success
    assert_match(/horas_extras_ana-souza_#{month.beginning_of_month.strftime('%Y%m%d')}_a_#{month.end_of_month.strftime('%Y%m%d')}\.pdf/, response.headers["Content-Disposition"])
  end

  test "export_pdf redirects with an alert when the filter has no records" do
    sign_in users(:one)
    next_month = Date.current.next_month

    get export_overtimes_pdf_path, params: {
      from: next_month.beginning_of_month.to_s,
      to: next_month.end_of_month.to_s
    }

    assert_redirected_to overtimes_path
    assert_equal "Não há horas extras no período selecionado para exportar.", flash[:alert]
  end

  test "export_xlsx redirects with an alert when the filter has no records" do
    sign_in users(:one)
    next_month = Date.current.next_month

    get export_overtimes_xlsx_path, params: {
      from: next_month.beginning_of_month.to_s,
      to: next_month.end_of_month.to_s
    }

    assert_redirected_to overtimes_path
    assert_equal "Não há horas extras no período selecionado para exportar.", flash[:alert]
  end

  test "export accepts the commit submit-button param without warnings" do
    sign_in users(:one)

    get export_overtimes_pdf_path, params: {
      commit: "Exportar PDF",
      from: Date.current.beginning_of_month.to_s,
      to: Date.current.end_of_month.to_s
    }

    assert_response :success
    assert response.body.start_with?("%PDF-")
  end
end
