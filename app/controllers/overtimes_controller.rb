class OvertimesController < ApplicationController
  include Pagy::Backend

  ITEMS_PER_PAGE = 20

  before_action :authenticate_user!
  before_action :set_overtime, only: %i[ show edit update destroy ]

  def index
    search = index_search_params
    @filter_start_date = filter_date(search[:start_at_gteq]) || Date.current.beginning_of_month
    @filter_end_date = filter_date(search[:start_at_lteq]) || Date.current.end_of_month

    # Date inputs are day-granular; widen them to full days in the app time
    # zone (America/Sao_Paulo) so both range ends are inclusive.
    @ransack = current_user.overtimes.ransack(
      search.merge(
        "start_at_gteq" => @filter_start_date.in_time_zone.beginning_of_day,
        "start_at_lteq" => @filter_end_date.in_time_zone.end_of_day
      )
    )
    @ransack.sorts = "start_at asc" if @ransack.sorts.empty?

    filtered = @ransack.result
    # The summary covers the whole filtered period, not just the visible page.
    @summary = filtered.sum(&:duration_minutes) / 60.0
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
    @overtime = current_user.overtimes.build
  end

  def create
    @overtime = current_user.overtimes.build(overtime_params)

    if @overtime.save
      redirect_to overtimes_path, notice: t("overtimes.create.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @overtime.update(overtime_params)
      redirect_to overtimes_path, notice: t("overtimes.update.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @overtime.discard!
    redirect_to overtimes_path, notice: t("overtimes.destroy.destroyed")
  end

  # The export form captures the active Ransack filter as plain `from`/`to`
  # query params, so these actions stay decoupled from `q[...]` internals.
  # The service re-applies the same kept + chronological scoping as the index.
  def export_pdf
    report = Overtimes::Export::Pdf.new(current_user, from: export_params[:from], to: export_params[:to])
    send_data report.render, filename: report.filename, type: report.content_type, disposition: "attachment"
  end

  def export_xlsx
    report = Overtimes::Export::Excel.new(current_user, from: export_params[:from], to: export_params[:to])
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
end
