class OvertimesController < ApplicationController
  include Pagy::Backend

  ITEMS_PER_PAGE = 20

  before_action :authenticate_user!
  before_action :set_overtime, only: %i[ show edit update destroy ]

  def index
    @ransack = build_ransack(index_search_params)
    @ransack.sorts = "start_at asc" if @ransack.sorts.empty?

    filtered = @ransack.result
    # The summary covers the whole filtered period, not just the visible page.
    # Computed in SQL (julianday) so large periods never load every row.
    @summary = filtered.sum_duration_minutes / 60.0
    @pagy, @overtimes = pagy(filtered, limit: ITEMS_PER_PAGE)

    respond_to do |format|
      format.html
      # Turbo form submissions accept turbo-stream, so redirect follows from
      # create/update/destroy land here as TURBO_STREAM without a page param.
      # Only the mobile infinite-scroll sentinel fetch (always ?page=N>1)
      # should render the stream; anything else gets the regular HTML page.
      format.turbo_stream do
        # formats: :html alone keeps the turbo-stream content type, which
        # would make Turbo process the whole page as a stream message.
        render :index, formats: :html, content_type: :html unless infinite_scroll_request?
      end
    end
  end

  def show
  end

  def new
    # Phase 6: pre-select today so the user only adjusts the times (SPEC §3
    # flow step 3). Edit keeps the stored values.
    @overtime = current_user.overtimes.build(start_at: Time.zone.now.beginning_of_day, end_at: Time.zone.now.beginning_of_day)
    set_filter_from_params
  end

  def create
    @overtime = current_user.overtimes.build(overtime_params)

    if @overtime.save
      set_filter_from_params
      @within_filter = within_filter?(@overtime)

      if @within_filter
        recompute_summary
        # The index shows the empty state (no list frame) when the filter has
        # no records; the stream must then replace it with the list instead of
        # appending to a table body that does not exist.
        @was_empty = @ransack.result.where.not(id: @overtime.id).empty?
        @pagy, @overtimes = pagy(@ransack.result, limit: ITEMS_PER_PAGE) if @was_empty
        flash.now[:notice] = t("overtimes.create.created")
        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to overtimes_path, notice: t("overtimes.create.created") }
        end
      else
        # Created outside the active filter: a plain redirect shows the list
        # (and the flash) instead of silently hiding the new record.
        redirect_to overtimes_path, notice: t("overtimes.create.created")
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    set_filter_from_params
  end

  def update
    if @overtime.update(overtime_params)
      set_filter_from_params
      @within_filter = within_filter?(@overtime)
      recompute_summary
      @filtered_empty = @ransack.result.empty?
      flash.now[:notice] = t("overtimes.update.updated")
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to overtimes_path, notice: t("overtimes.update.updated") }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @overtime.discard!
    set_filter_from_params
    recompute_summary
    @filtered_empty = @ransack.result.empty?
    flash.now[:notice] = t("overtimes.destroy.destroyed")
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to overtimes_path, notice: t("overtimes.destroy.destroyed") }
    end
  end

  # The export form captures the active Ransack filter as plain `from`/`to`
  # query params, so these actions stay decoupled from `q[...]` internals.
  # The service re-applies the same kept + chronological scoping as the index.
  # An empty filtered set redirects with an alert instead of generating an
  # empty file (SPEC §6: exports only make sense when there is data).
  def export_pdf
    report = Overtimes::Export::Pdf.new(current_user, from: export_params[:from], to: export_params[:to])
    return redirect_to overtimes_path, alert: t("overtimes.export.empty_filter") if report.overtimes.empty?

    send_data report.render, filename: report.filename, type: report.content_type, disposition: "attachment"
  end

  def export_xlsx
    report = Overtimes::Export::Excel.new(current_user, from: export_params[:from], to: export_params[:to])
    return redirect_to overtimes_path, alert: t("overtimes.export.empty_filter") if report.overtimes.empty?

    send_data report.render, filename: report.filename, type: report.content_type, disposition: "attachment"
  end

  private
    def set_overtime
      # Scoped through current_user: other users' records (kept or
      # discarded) raise RecordNotFound -> 404 (SPEC R9 / AC-12).
      @overtime = current_user.overtimes.find(params[:id])
    end

    def overtime_params
      params.expect(overtime: [ :start_at, :end_at, :description ])
    end

    def export_params
      params.permit(:from, :to)
    end

    def index_search_params
      params[:q]&.permit(:start_at_gteq, :start_at_lteq, :s)&.to_h || {}
    end

    # True for the mobile sentinel's next-page fetch (infinite_scroll_controller.js).
    def infinite_scroll_request?
      params[:page].to_i > 1
    end

    def filter_date(value)
      Date.parse(value.to_s)
    rescue ArgumentError, TypeError
      nil
    end

    # Builds the Ransack search for the active date range and sets the
    # @filter_start_date/@filter_end_date display bounds. Date inputs are
    # day-granular; they are widened to full days in the app time zone
    # (America/Sao_Paulo) so both range ends are inclusive (SPEC §5 R8).
    def build_ransack(search)
      @filter_start_date = filter_date(search[:start_at_gteq]) || Date.current.beginning_of_month
      @filter_end_date = filter_date(search[:start_at_lteq]) || Date.current.end_of_month

      current_user.overtimes.ransack(
        search.merge(
          "start_at_gteq" => @filter_start_date.in_time_zone.beginning_of_day,
          "start_at_lteq" => @filter_end_date.in_time_zone.end_of_day
        )
      )
    end

    # create/update/destroy receive the active filter as plain `from`/`to`
    # params (hidden fields in the form), mirroring the export forms, so the
    # summary and the append/replace/remove decisions stay in sync with what
    # the user was looking at.
    def set_filter_from_params
      search = {}
      search[:start_at_gteq] = params[:from] if params[:from].present?
      search[:start_at_lteq] = params[:to] if params[:to].present?
      @ransack = build_ransack(search)
    end

    def recompute_summary
      @summary = @ransack.result.sum_duration_minutes / 60.0
    end

    def within_filter?(overtime)
      overtime.start_at >= @filter_start_date.in_time_zone.beginning_of_day &&
        overtime.start_at <= @filter_end_date.in_time_zone.end_of_day
    end
end
