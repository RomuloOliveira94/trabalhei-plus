module Overtimes
  module Export
    # Shared foundation for every export format. Kept thin: the heavy lifting
    # (duration maths, HH:MM formatting, kept scoping) lives in Overtime; this
    # class only decides *which* records to export and how to label them.
    #
    # Subclasses implement #render (returning the binary payload) and expose
    # #content_type / #filename so controllers can hand the result straight to
    # `send_data`.
    class Base
      attr_reader :user, :from, :to

      # +from+/+to+ are day-granular dates (SPEC §5 R8: displayed in
      # America/Sao_Paulo). Nil defaults to the current month.
      def initialize(user, from: nil, to: nil)
        @user = user
        @from = normalize_date(from) || Date.current.beginning_of_month
        @to = normalize_date(to) || Date.current.end_of_month
      end

      # Kept only (SPEC R11) — discarded records never reach an export. The
      # date range is widened to full days in the app zone so both ends are
      # inclusive, mirroring the controller filter.
      def overtimes
        @overtimes ||= user.overtimes.kept
          .within_period(from.in_time_zone.beginning_of_day, to.in_time_zone.end_of_day)
          .chronological
      end

      def total_duration_minutes
        @total_duration_minutes ||= overtimes.sum(&:duration_minutes)
      end

      # Formal HH:MM total for the report footer (SPEC R13).
      def formatted_total
        format("%02d:%02d", total_duration_minutes / 60, total_duration_minutes.modulo(60))
      end

      def period_label
        "#{I18n.l(from, format: :short_date)} a #{I18n.l(to, format: :short_date)}"
      end

      # SPEC AC-6: horas-extras_<nome-slug>_<de>_a_<ate>.<ext>. Dates use a
      # sortable YYYYMMDD so filenames order chronologically.
      def filename_base
        "horas_extras_#{user.name.parameterize}_#{from.strftime('%Y%m%d')}_a_#{to.strftime('%Y%m%d')}"
      end

      def filename
        "#{filename_base}.#{extension}"
      end

      def render
        raise NotImplementedError
      end

      def content_type
        raise NotImplementedError
      end

      # Column order shared by PDF and Excel (SPEC §6 AC-6/AC-7).
      def column_labels
        [
          I18n.t("overtimes.export.column_date"),
          I18n.t("overtimes.export.column_start"),
          I18n.t("overtimes.export.column_end"),
          I18n.t("overtimes.export.column_duration"),
          I18n.t("overtimes.export.column_description")
        ]
      end

      def row_for(overtime)
        [
          I18n.l(overtime.start_at, format: :short_date),
          I18n.l(overtime.start_at, format: :hours_minutes),
          I18n.l(overtime.end_at, format: :hours_minutes),
          overtime.duration_formatted_export,
          overtime.description
        ]
      end

      private
        def extension
          raise NotImplementedError
        end

        def normalize_date(value)
          return value if value.is_a?(Date)

          Date.parse(value.to_s)
        rescue ArgumentError, TypeError
          nil
        end
    end
  end
end
