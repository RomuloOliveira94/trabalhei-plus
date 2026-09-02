require "test_helper"
require "nokogiri"

class Overtimes::Export::ExcelTest < ActiveSupport::TestCase
  # The xlsx parts live in the SpreadsheetML namespace, so every XPath below
  # has to go through a prefix. Reading attributes by name (instead of
  # matching the serialized tag) keeps these helpers immune to caxlsx
  # reordering or adding attributes between releases.
  SPREADSHEET_NS = { "s" => "http://schemas.openxmlformats.org/spreadsheetml/2006/main" }.freeze

  def build_report(user, from: nil, to: nil)
    Overtimes::Export::Excel.new(user, from: from, to: to)
  end

  def zip_entry(binary, name)
    entry = nil
    Zip::File.open_buffer(binary) do |zip|
      entry = zip.get_entry(name).get_input_stream.read.force_encoding(Encoding::UTF_8)
    end
    entry
  end

  def sheet_xml(binary, sheet: 1)
    Nokogiri::XML(zip_entry(binary, "xl/worksheets/sheet#{sheet}.xml"))
  end

  # caxlsx writes cell text inline (`t="inlineStr"`), so the sheet XML alone is
  # enough to assert on positions. Returns one array of [ column, text ] pairs
  # per row, e.g. [ [ "A", "Data" ], [ "B", "Início" ], ... ]. Cells with no
  # value (the padding of the total row) come back with a nil text.
  def sheet_cells(binary, sheet: 1)
    sheet_xml(binary, sheet: sheet).xpath("//s:sheetData/s:row", SPREADSHEET_NS).map do |row|
      row.xpath("s:c", SPREADSHEET_NS).map do |cell|
        [ cell["r"][/\A[A-Z]+/], cell.at_xpath("s:is/s:t", SPREADSHEET_NS)&.text ]
      end
    end
  end

  # The <xf> cell format a given cell points at, so alignment can be asserted.
  def cell_format(binary, reference)
    cell = sheet_xml(binary).at_xpath("//s:c[@r='#{reference}']", SPREADSHEET_NS)
    formats = Nokogiri::XML(zip_entry(binary, "xl/styles.xml")).xpath("//s:cellXfs/s:xf", SPREADSHEET_NS)

    formats[cell["s"].to_i]
  end

  # Declared width of a 1-based column index, from the sheet's <cols> block.
  def column_width(binary, index, sheet: 1)
    column = sheet_xml(binary, sheet: sheet)
      .at_xpath("//s:cols/s:col[@min='#{index}'][@max='#{index}']", SPREADSHEET_NS)

    column && column["width"].to_f
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

  test "the period total sits in the last column, not under Início" do
    report = build_report(users(:one))

    rows = sheet_cells(report.render)
    header = rows.first
    total = rows.last

    assert_equal "Total de horas no período", total.first.last
    assert_equal "E", header.last.first, "the sheet must have five columns"

    value = total.find { |_column, text| text == report.formatted_total }

    assert_not_nil value, "the total value is missing from the total row"
    assert_equal "E", value.first, "the total must line up with the PDF footer, not with Início"
  end

  test "description cells wrap inside their fixed column width" do
    binary = build_report(users(:one)).render

    alignment = cell_format(binary, "E2").at_xpath("s:alignment", SPREADSHEET_NS)

    assert_includes %w[ 1 true ], alignment["wrapText"]
    assert_equal "top", alignment["vertical"]
    assert_equal 60.0, column_width(binary, 5)
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
