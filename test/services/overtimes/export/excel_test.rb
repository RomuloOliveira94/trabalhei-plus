require "test_helper"
require "zip"

class Overtimes::Export::ExcelTest < ActiveSupport::TestCase
  def build_report(user, from: nil, to: nil)
    Overtimes::Export::Excel.new(user, from: from, to: to)
  end

  # Concatenates every XML part of the workbook so assertions can grep for
  # shared-string content (caxlsx stores cell text in sharedStrings.xml).
  # NB: Zip::File.open_buffer returns the underlying buffer, not the block's
  # value, so the result is captured in a local instead.
  def xlsx_text(report)
    text = +""
    Zip::File.open_buffer(report.render) do |zip|
      zip.entries.select { |entry| entry.name.end_with?(".xml") }.each do |entry|
        # XLSX XML parts are UTF-8; rubyzip reads raw bytes.
        text << entry.get_input_stream.read.force_encoding(Encoding::UTF_8)
      end
    end
    text
  end

  test "renders a parseable xlsx package with main and summary sheets" do
    report = build_report(users(:one))

    binary = report.render
    assert binary.start_with?("PK") # ZIP magic bytes
    assert_equal "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", report.content_type

    entries = nil
    Zip::File.open_buffer(binary) { |zip| entries = zip.entries.map(&:name) }
    assert_includes entries, "xl/workbook.xml"
    assert_includes entries, "xl/worksheets/sheet1.xml"
    assert_includes entries, "xl/worksheets/sheet2.xml"
  end

  test "main sheet includes header labels and data rows" do
    report = build_report(users(:one))
    text = xlsx_text(report)

    %w[ Data Início Fim Duração Descrição ].each { |label| assert_includes text, label }
    assert_includes text, "Fechamento do relatório mensal"
  end

  test "total row holds the period total" do
    report = build_report(users(:one))
    text = xlsx_text(report)

    assert_includes text, "Total de horas no período"
    assert_includes text, "03:30"
  end

  test "summary sheet holds the employee block" do
    report = build_report(users(:one))
    text = xlsx_text(report)

    assert_includes text, "Ana Souza"
    assert_includes text, "ana@example.com"
  end

  test "only includes the given user's kept records" do
    report = build_report(users(:one))
    text = xlsx_text(report)

    assert_includes text, "Fechamento do relatório mensal"
    assert_not_includes text, "Plantão do Bruno"
    assert_not_includes text, "Registro lançado por engano"
  end
end
