require "test_helper"

class Overtimes::Export::PdfTest < ActiveSupport::TestCase
  def build_report(user, from: nil, to: nil)
    Overtimes::Export::Pdf.new(user, from: from, to: to)
  end

  # Parses the PDF content streams into a geometry dump: filled rectangles
  # (cell backgrounds, with their fill color) and text runs (position + text).
  # Prawn draws table cell backgrounds as `x y w h re f` and text as
  # `BT x y Td /F 9 Tf <hex> Tj ET` (or a `[<hex> ...] TJ` array when the
  # line needs kerning adjustments, as wrapped description lines do).
  def pdf_geometry(pdf)
    raw = pdf.b
    cmap = {}
    raw.scan(/beginbfchar\n(.*?)\nendbfchar/m).each do |block|
      block[0].scan(/<([0-9A-Fa-f]+)><([0-9A-Fa-f]+)>/).each do |code, uni|
        cmap[code.to_i(16)] = [ uni ].pack("H*").force_encoding("UTF-16BE").encode("UTF-8")
      end
    end
    raw.scan(/beginbfrange\n(.*?)\nendbfrange/m).each do |block|
      block[0].scan(/<([0-9A-Fa-f]+)><([0-9A-Fa-f]+)><([0-9A-Fa-f]+)>/).each do |lo, hi, uni|
        lo_i = lo.to_i(16)
        hi_i = hi.to_i(16)
        uni_i = uni.to_i(16)
        (lo_i..hi_i).each_with_index { |code, i| cmap[code] = [ uni_i + i ].pack("U") }
      end
    end

    rects = []
    runs = []
    fill = nil
    position = nil
    raw.scan(/stream\r?\n(.*?)\r?\nendstream/m).each do |(stream)|
      stream.each_line do |line|
        case line
        when /^([\d.]+) ([\d.]+) ([\d.]+) scn$/
          fill = [ $1, $2, $3 ].map(&:to_f)
        when /^([\d.]+) ([\d.]+) ([\d.]+) ([\d.]+) re$/
          rects << { x: $1.to_f, y: $2.to_f, width: $3.to_f, height: $4.to_f, fill: fill }
        when /^([\d.]+) ([\d.]+) Td$/
          position = [ $1.to_f, $2.to_f ]
        when /^<([0-9A-Fa-f]+)> Tj$/
          runs << { x: position[0], y: position[1], text: decode_hex($1, cmap) } if position
        when /^\[(.*?)\] TJ$/
          text = $1.scan(/<([0-9A-Fa-f]+)>/).map { |(hex)| decode_hex(hex, cmap) }.join
          runs << { x: position[0], y: position[1], text: text } if position
        end
      end
    end
    { rects: rects, runs: runs }
  end

  def decode_hex(hex, cmap)
    hex.scan(/../).map { |byte| cmap[byte.to_i(16)] || byte.to_i(16).chr }.join
  end

  test "renders a valid PDF for a user with records in the period" do
    report = build_report(users(:one))

    pdf = report.render

    assert pdf.start_with?("%PDF-")
    assert_equal "application/pdf", report.content_type
  end

  test "subheader shows the user's name only, without the email" do
    report = build_report(users(:one))

    text = pdf_text(report.render)

    assert_match "Usuário: Ana Souza", text
    assert_no_match /ana@example\.com/, text
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

  test "fixed column widths keep headers on one line and wrap long descriptions" do
    # 700-char description forces the description cell to wrap across lines.
    overtimes(:one).update!(description: ("Palavra " * 100).strip)

    geometry = pdf_geometry(build_report(users(:one)).render)

    # Header row background (E5E5E5) rectangles expose the column widths.
    header_rects = geometry[:rects].select { |r| r[:fill]&.first&.round(3) == 0.898 }
    widths = header_rects.sort_by { |r| r[:x] }.map { |r| r[:width] }

    assert_equal [ 65.0, 50.0, 50.0, 60.0 ], widths[0, 4], "Data/Início/Fim/Duração must use the fixed widths"
    assert_in_delta 290.28, widths[4], 0.01, "description takes the remaining width"
    assert_in_delta 515.28, widths.sum, 0.01, "columns must fill the usable A4 width"

    # Headers render as single text runs (no "Iníci"+"o" vertical break).
    header_texts = geometry[:runs].select { |r| r[:y] > 682 }.map { |r| r[:text] }
    %w[Data Início Fim Duração Descrição].each do |label|
      assert_includes header_texts, label, "#{label} header must render on a single line"
    end
    refute_includes header_texts, "Iníci"
    refute_includes header_texts, "Duraç"

    # The body date must also stay on one line (the original bug: "01/09/20\n26").
    body_texts = geometry[:runs].select { |r| r[:y] < 682 && r[:y] > 560 }.map { |r| r[:text] }
    assert_includes body_texts, "01/09/2026"

    # Description wraps: multiple runs in the description column (x > 265),
    # below the header, above the total row.
    description_runs = geometry[:runs].select { |r| r[:x] > 265 && r[:y] < 682 && r[:y] > 560 }
    assert_operator description_runs.size, :>, 2, "long description must wrap across multiple lines"
    assert_operator description_runs.map { |r| r[:text].length }.sum, :>, 500
  end
end
