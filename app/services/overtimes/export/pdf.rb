module Overtimes
  module Export
    class Pdf < Base
      require "prawn"
      require "prawn/table"

      DEJAVU_PATH = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
      DEJAVU_BOLD_PATH = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"

      # Prawn's built-in Helvetica uses WinAnsi encoding, which already maps
      # every pt-BR accented character (á é í ó ú â ê ô ã õ ç à) correctly. It
      # is a valid fallback, but it also emits a one-time m17n warning for any
      # non-ASCII text. Where DejaVu Sans is present (most Linux distros, and
      # this dev machine), we prefer it for full Unicode coverage and clean
      # output; otherwise we fall back to Helvetica.
      def self.dejavu_family
        @dejavu_family ||= begin
          if File.exist?(DEJAVU_PATH) && File.exist?(DEJAVU_BOLD_PATH)
            {
              "DejaVu Sans" => {
                normal: DEJAVU_PATH,
                bold: DEJAVU_BOLD_PATH,
                italic: DEJAVU_PATH,
                bold_italic: DEJAVU_BOLD_PATH
              }
            }
          end
        end
      end

      def render
        doc = Prawn::Document.new(page_size: "A4", margin: 40)
        register_font(doc)

        doc.text I18n.t("overtimes.export.pdf_title"), size: 16, style: :bold, align: :center
        doc.move_down 14

        doc.text I18n.t("overtimes.export.usuario", name: user.name), size: 11
        doc.move_down 6
        doc.text I18n.t("overtimes.export.period", period: period_label), size: 11
        doc.move_down 6
        doc.text I18n.t("overtimes.export.generated_at", datetime: generated_at), size: 9, color: "666666", align: :right
        doc.move_down 14

        doc.table(table_rows(doc), header: true, width: doc.bounds.width, row_colors: %w[FFFFFF F5F5F5], cell_style: { size: 9, border_width: 0.5 }) do
          row(0).font_style = :bold
          row(0).background_color = "DC2626"
          row(0).text_color = "FFFFFF"
          cells.padding = [ 6, 8, 6, 8 ]
        end

        doc.render
      end

      def content_type
        "application/pdf"
      end

      private
        def extension
          "pdf"
        end

        def register_font(doc)
          return unless (family = self.class.dejavu_family)

          doc.font_families.update(family)
          doc.font "DejaVu Sans"
        end

        def generated_at
          I18n.l(Time.current, format: :short_datetime)
        end

        def table_rows(doc)
          rows = [ column_labels ]
          rows.concat(overtimes.map { |overtime| row_for(overtime) })
          rows << total_row(doc)
          rows
        end

        # Last row: label spanning the first four columns, value in the last.
        def total_row(doc)
          [
            doc.make_cell(content: I18n.t("overtimes.export.total"), colspan: 4, font_style: :bold),
            doc.make_cell(content: formatted_total, font_style: :bold, align: :right)
          ]
        end
    end
  end
end
