require "test_helper"

class OvertimesTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @current_month_day = Date.current.beginning_of_month.strftime("%Y-%m-%d")
    @previous_month = Date.current.prev_month
  end

  test "requires authentication" do
    get overtimes_path

    assert_redirected_to new_user_session_path
  end

  test "index lists only the current user's kept overtimes" do
    sign_in users(:one)
    get overtimes_path

    assert_response :success
    assert_select "td", "Fechamento do relatório mensal"
    assert_no_match /Plantão do Bruno/, response.body
    assert_no_match /Registro lançado por engano/, response.body
  end

  test "show of another user's overtime returns 404" do
    sign_in users(:one)
    get overtime_path(overtimes(:from_bruno))

    assert_response :not_found
  end

  test "edit of another user's overtime returns 404" do
    sign_in users(:one)
    get edit_overtime_path(overtimes(:from_bruno))

    assert_response :not_found
  end

  test "update of another user's overtime returns 404" do
    sign_in users(:one)
    patch overtime_path(overtimes(:from_bruno)), params: { overtime: { description: "hack" } }

    assert_response :not_found
    assert_equal "Plantão do Bruno", overtimes(:from_bruno).reload.description
  end

  test "destroy of another user's overtime returns 404 and keeps it" do
    sign_in users(:one)
    delete overtime_path(overtimes(:from_bruno))

    assert_response :not_found
    assert_nil overtimes(:from_bruno).reload.discarded_at
  end

  test "creates a valid overtime for the current user" do
    sign_in users(:one)

    assert_difference -> { users(:one).overtimes.count }, 1 do
      post overtimes_path, params: { overtime: {
        start_at: "#{@current_month_day}T18:00",
        end_at: "#{@current_month_day}T20:00",
        description: "Deploy urgente"
      } }
    end

    assert_redirected_to overtimes_path

    overtime = users(:one).overtimes.last
    assert_equal Time.zone.local(Date.current.year, Date.current.month, 1, 18, 0, 0), overtime.start_at
    # Stored as UTC behind the scenes (SPEC R7): 18:00 BRT == 21:00 UTC.
    assert_equal 21, overtime.start_at.utc.hour

    follow_redirect!
    assert_match "Deploy urgente", response.body
  end

  test "create accepts the commit submit-button param" do
    sign_in users(:one)

    assert_difference -> { users(:one).overtimes.count }, 1 do
      post overtimes_path, params: { commit: "Salvar", overtime: {
        start_at: "#{@current_month_day}T18:00",
        end_at: "#{@current_month_day}T20:00",
        description: "Com botão de submit"
      } }
    end

    assert_redirected_to overtimes_path
  end

  test "create with end before start re-renders the form with errors" do
    sign_in users(:one)

    assert_no_difference -> { Overtime.count } do
      post overtimes_path, params: { overtime: {
        start_at: "#{@current_month_day}T20:00",
        end_at: "#{@current_month_day}T18:00",
        description: "Invertido"
      } }
    end

    assert_response :unprocessable_entity
    assert_select "div#error_explanation"
    assert_match "deve ser depois do início", response.body
  end

  test "create shorter than 5 minutes is invalid" do
    sign_in users(:one)

    assert_no_difference -> { Overtime.count } do
      post overtimes_path, params: { overtime: {
        start_at: "#{@current_month_day}T18:00",
        end_at: "#{@current_month_day}T18:04",
        description: "Muito curto"
      } }
    end

    assert_response :unprocessable_entity
    assert_match "no mínimo 5 minutos", response.body
  end

  test "updates an overtime" do
    sign_in users(:one)
    overtime = overtimes(:one)

    patch overtime_path(overtime), params: { overtime: { description: "Descrição revisada" } }

    assert_redirected_to overtimes_path
    assert_equal "Descrição revisada", overtime.reload.description
  end

  test "update with invalid data re-renders the form with errors" do
    sign_in users(:one)
    overtime = overtimes(:one)

    patch overtime_path(overtime), params: { overtime: {
      start_at: overtime.start_at,
      end_at: overtime.start_at - 1.hour,
      description: overtime.description
    } }

    assert_response :unprocessable_entity
    assert_select "div#error_explanation"
  end

  test "destroy soft deletes: hidden from index, row kept in the database" do
    sign_in users(:one)
    overtime = overtimes(:one)

    assert_no_difference -> { Overtime.with_discarded.count } do
      delete overtime_path(overtime)
    end

    assert_redirected_to overtimes_path
    assert overtime.reload.discarded_at.present?

    get overtimes_path
    assert_no_match /Fechamento do relatório mensal/, response.body
  end

  test "default filter shows only the current month" do
    sign_in users(:one)
    get overtimes_path

    assert_match "Fechamento do relatório mensal", response.body
    assert_no_match /Suporte ao deploy/, response.body
  end

  test "explicit date range filter shows the matching period" do
    sign_in users(:one)
    get overtimes_path, params: { q: {
      start_at_gteq: @previous_month.beginning_of_month.to_s,
      start_at_lteq: @previous_month.end_of_month.to_s
    } }

    assert_match "Suporte ao deploy", response.body
    assert_no_match /Fechamento do relatório mensal/, response.body
    # The filter inputs repopulate with the submitted range.
    assert_select "input[name='q[start_at_gteq]'][value=?]", @previous_month.beginning_of_month.to_s
    assert_select "input[name='q[start_at_lteq]'][value=?]", @previous_month.end_of_month.to_s
  end

  test "invalid date params fall back to the current month" do
    sign_in users(:one)
    get overtimes_path, params: { q: { start_at_gteq: "not-a-date" } }

    assert_response :success
    assert_match "Fechamento do relatório mensal", response.body
  end

  test "summary shows the total hours of the filtered period" do
    sign_in users(:one)
    get overtimes_path

    # Fixture "one" is 3.5h long and is the only kept record of the month.
    assert_match "3,5h", response.body
  end

  test "summary follows the custom date range" do
    sign_in users(:one)
    get overtimes_path, params: { q: {
      start_at_gteq: @previous_month.beginning_of_month.to_s,
      start_at_lteq: @previous_month.end_of_month.to_s
    } }

    # Fixture "previous_month" is 2h long.
    assert_match "2,0h", response.body
  end

  test "summary is computed in SQL: correct total with 1000 records, no row-by-row loading" do
    sign_in users(:one)
    month_start = Date.current.beginning_of_month.in_time_zone.beginning_of_day

    # 1000 kept records of exactly 30 minutes within the current month. Built
    # with insert_all (no callbacks) so the test stays fast — the summary only
    # reads start_at/end_at.
    Overtime.insert_all(
      Array.new(1000) do |i|
        start_at = month_start + (i % 28).days + (i % 120).minutes
        {
          user_id: users(:one).id,
          start_at: start_at,
          end_at: start_at + 30.minutes,
          description: "Registro em massa #{i}",
          created_at: Time.current,
          updated_at: Time.current
        }
      end
    )

    queries = []
    subscriber = ->(_name, _started, _finished, _id, payload) { queries << payload[:sql] unless payload[:cached] }
    ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") do
      get overtimes_path
    end

    assert_response :success
    # 1000 × 30 min = 500h + the 3.5h "one" fixture = 503.5h.
    assert_match "503,5h", response.body
    # The summary must be a single SQL aggregate, not a row-by-row load.
    assert queries.any? { |sql| sql.match?(/SELECT SUM/i) }, "expected a SQL SUM aggregate for the summary"
    assert_operator queries.length, :<=, 20, "expected a bounded number of queries (no N+1)"
  end
end
