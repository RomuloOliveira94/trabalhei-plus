module Overtimes
  module Export
    class Excel < Base
      require "caxlsx"

      # Builds the workbook and returns the raw .xlsx binary. Kept here (rather
      # than a caxlsx_rails view template) so the service is directly unit-
      # testable per SPEC §8 and can be handed to `send_data` like the PDF.
      # The caxlsx_rails renderer remains available for future `respond_to :xlsx`.
      def render
        package.to_stream.read
      end

      def content_type
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      end

      private
        def extension
          "xlsx"
        end

        def package
          Axlsx::Package.new do |p|
            p.workbook.add_worksheet(name: I18n.t("overtimes.export.sheet_main")) do |sheet|
              add_main_sheet(sheet)
            end
            p.workbook.add_worksheet(name: I18n.t("overtimes.export.sheet_summary")) do |sheet|
              add_summary_sheet(sheet)
            end
          end
        end

        def add_main_sheet(sheet)
          header_style = sheet.styles.add_style(b: true, border: { style: :thin, color: "999999" })
          total_style = sheet.styles.add_style(b: true)

          sheet.add_row column_labels, style: header_style
          overtimes.each { |overtime| sheet.add_row row_for(overtime) }
          sheet.add_row [ I18n.t("overtimes.export.total"), formatted_total ], style: total_style

          sheet.column_widths 12, 8, 8, 12, 60
        end

        def add_summary_sheet(sheet)
          label_style = sheet.styles.add_style(b: true)

          [
            [ I18n.t("overtimes.export.employee_label"), user.name ],
            [ I18n.t("overtimes.export.email_label"), user.email ],
            [ I18n.t("overtimes.export.period_label"), period_label ],
            [ I18n.t("overtimes.export.total_label"), formatted_total ]
          ].each { |row| sheet.add_row row, style: label_style }

          sheet.column_widths 20, 40
        end
    end
  end
end
