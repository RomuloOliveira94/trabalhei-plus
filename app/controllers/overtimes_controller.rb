class OvertimesController < ApplicationController
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

    @overtimes = @ransack.result
    @summary = @overtimes.sum(&:duration_minutes) / 60.0
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

  private
    def set_overtime
      # Scoped through current_user: other users' records (kept or
      # discarded) raise RecordNotFound -> 404 (SPEC R9 / AC-12).
      @overtime = current_user.overtimes.find(params[:id])
    end

    def overtime_params
      params.expect(overtime: [ :start_at, :end_at, :description ])
    end

    def index_search_params
      params[:q]&.permit(:start_at_gteq, :start_at_lteq, :s)&.to_h || {}
    end

    def filter_date(value)
      Date.parse(value.to_s)
    rescue ArgumentError, TypeError
      nil
    end
end
