require "application_system_test_case"
require "tmpdir"

class ExportButtonsTest < ApplicationSystemTestCase
  setup do
    @downloads = Dir.mktmpdir("exports")
    page.driver.browser.download_path = @downloads
    sign_in users(:one)
  end

  teardown do
    FileUtils.remove_entry(@downloads) if @downloads && Dir.exist?(@downloads)
  end

  test "export buttons carry the active filter and download a PDF" do
    visit overtimes_path

    pdf_form = page.find("form[action='#{export_overtimes_pdf_path}']")
    assert_equal Date.current.beginning_of_month.to_s, pdf_form.find("input[name='from']", visible: false).value
    assert_equal Date.current.end_of_month.to_s, pdf_form.find("input[name='to']", visible: false).value

    click_button "Exportar PDF"

    downloaded = wait_for_download(/\.pdf\z/)
    assert downloaded, "expected a .pdf file to be downloaded"
    assert_match(/horas_extras_ana-souza_\d{8}_a_\d{8}\.pdf/, downloaded)

    text = pdf_text(File.binread(downloaded))
    assert_match "Usuário: Ana Souza", text
    assert_no_match /ana@example\.com/, text
  end

  test "excel button downloads an xlsx" do
    visit overtimes_path

    click_button "Exportar Excel"

    downloaded = wait_for_download(/\.xlsx\z/)
    assert downloaded, "expected a .xlsx file to be downloaded"
    assert_match(/horas_extras_ana-souza_\d{8}_a_\d{8}\.xlsx/, downloaded)

    text = xlsx_text(File.binread(downloaded))
    assert_includes text, "Usuário"
    assert_includes text, "Ana Souza"
    assert_not_includes text, "ana@example.com"
  end

  test "export respects the active Ransack filter" do
    month = Date.current.prev_month
    visit overtimes_path(q: {
      start_at_gteq: month.beginning_of_month.to_s,
      start_at_lteq: month.end_of_month.to_s
    })

    pdf_form = page.find("form[action='#{export_overtimes_pdf_path}']")
    assert_equal month.beginning_of_month.to_s, pdf_form.find("input[name='from']", visible: false).value
    assert_equal month.end_of_month.to_s, pdf_form.find("input[name='to']", visible: false).value

    click_button "Exportar PDF"

    downloaded = wait_for_download(/\.pdf\z/)
    assert downloaded, "expected a .pdf file to be downloaded"
    assert_match(/horas_extras_ana-souza_#{month.beginning_of_month.strftime('%Y%m%d')}_a_#{month.end_of_month.strftime('%Y%m%d')}\.pdf/, downloaded)
  end

  private
    def wait_for_download(pattern, timeout: 10)
      deadline = Time.now + timeout
      while Time.now < deadline
        file = Dir.glob(File.join(@downloads, "*")).find { |entry| entry.match?(pattern) }
        return file if file

        sleep 0.2
      end
      nil
    end
end
