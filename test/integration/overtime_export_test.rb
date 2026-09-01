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
end
