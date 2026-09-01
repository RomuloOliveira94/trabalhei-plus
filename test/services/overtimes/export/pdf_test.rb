require "test_helper"

class Overtimes::Export::PdfTest < ActiveSupport::TestCase
  def build_report(user, from: nil, to: nil)
    Overtimes::Export::Pdf.new(user, from: from, to: to)
  end

  test "renders a valid PDF for a user with records in the period" do
    report = build_report(users(:one))

    pdf = report.render

    assert pdf.start_with?("%PDF-")
    assert_equal "application/pdf", report.content_type
  end

  test "renders an empty-but-valid PDF with a zero total when nothing matches" do
    next_month = Date.current.next_month
    report = build_report(users(:one), from: next_month.beginning_of_month, to: next_month.end_of_month)

    assert report.render.start_with?("%PDF-")
    assert_empty report.overtimes
    assert_equal "00:00", report.formatted_total
  end

  test "totals the minutes of the period as zero-padded HH:MM" do
    # Fixture `one` (3.5h) + `previous_month` (2h) = 5.5h = 330 minutes.
    report = build_report(
      users(:one),
      from: Date.current.prev_month.beginning_of_month,
      to: Date.current.end_of_month
    )

    assert_equal 330, report.total_duration_minutes
    assert_equal "05:30", report.formatted_total
  end

  test "filename includes the slugged user name and period" do
    from = Date.current.beginning_of_month
    to = Date.current.end_of_month
    report = build_report(users(:one), from: from, to: to)

    assert_equal "horas_extras_ana-souza_#{from.strftime('%Y%m%d')}_a_#{to.strftime('%Y%m%d')}.pdf", report.filename
  end

  test "only includes the given user's kept records" do
    report = build_report(
      users(:one),
      from: Date.current.prev_month.beginning_of_month,
      to: Date.current.end_of_month
    )

    descriptions = report.overtimes.map(&:description)

    assert_includes descriptions, "Fechamento do relatório mensal"
    assert_includes descriptions, "Suporte ao deploy de sábado"
    assert_not_includes descriptions, "Plantão do Bruno"
    assert_not_includes descriptions, "Registro lançado por engano"
  end
end
