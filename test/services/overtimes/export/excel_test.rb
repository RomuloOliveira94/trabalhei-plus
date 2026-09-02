require "test_helper"

class Overtimes::Export::ExcelTest < ActiveSupport::TestCase
  def build_report(user, from: nil, to: nil)
    Overtimes::Export::Excel.new(user, from: from, to: to)
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
    text = xlsx_text(report.render)

    %w[ Data Início Fim Duração Descrição ].each { |label| assert_includes text, label }
    assert_includes text, "Fechamento do relatório mensal"
  end

  test "total row holds the period total" do
    report = build_report(users(:one))
    text = xlsx_text(report.render)

    assert_includes text, "Total de horas no período"
    assert_includes text, "03:30"
  end

  test "total row matches the sum of the per-row durations" do
    # See the PDF test: julianday returns 60.99999971687794 for this record.
    month_start = Date.current.beginning_of_month
    overtimes(:one).update!(
      start_at: Time.zone.local(month_start.year, month_start.month, month_start.day, 16, 2, 0),
      end_at: Time.zone.local(month_start.year, month_start.month, month_start.day, 17, 3, 0)
    )

    report = build_report(users(:one), from: month_start, to: month_start.end_of_month)
    row_minutes = report.overtimes.sum do |overtime|
      hours, minutes = overtime.duration_formatted_export.split(":").map(&:to_i)
      hours * 60 + minutes
    end

    assert_equal format("%02d:%02d", row_minutes / 60, row_minutes % 60), report.formatted_total
    assert_includes xlsx_text(report.render), "01:01"
  end

  test "summary sheet holds the user block without the email" do
    report = build_report(users(:one))
    text = xlsx_text(report.render)

    assert_includes text, "Usuário"
    assert_includes text, "Ana Souza"
    assert_not_includes text, "ana@example.com"
  end

  test "only includes the given user's kept records" do
    report = build_report(users(:one))
    text = xlsx_text(report.render)

    assert_includes text, "Fechamento do relatório mensal"
    assert_not_includes text, "Plantão do Bruno"
    assert_not_includes text, "Registro lançado por engano"
  end
end
