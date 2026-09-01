require "test_helper"

class OvertimesPaginationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    # The pagination fixtures live two months back (25 records per user),
    # so every request filters that month explicitly.
    @month = Date.current << 2
    @range = {
      start_at_gteq: @month.beginning_of_month.to_s,
      start_at_lteq: @month.end_of_month.to_s
    }
  end

  test "index paginates: first page holds 20 of 25 records" do
    sign_in users(:one)
    get overtimes_path, params: { q: @range }

    assert_response :success
    assert_select "table tbody tr", count: 20
    assert_select "nav[aria-label='Paginação']"
    # Pager links keep the active Ransack filter.
    assert_select "a[href*='page=2'][href*='start_at_gteq']"
  end

  test "second page holds the remaining 5 records" do
    sign_in users(:one)
    get overtimes_path, params: { q: @range, page: 2 }

    assert_response :success
    assert_select "table tbody tr", count: 5
  end

  test "out-of-range page renders the last page instead of 404" do
    sign_in users(:one)
    get overtimes_path, params: { q: @range, page: 99 }

    assert_response :success
    assert_select "table tbody tr", count: 5
  end

  test "pagination keeps the per-user scope across pages" do
    sign_in users(:one)
    get overtimes_path, params: { q: @range }
    assert_no_match /Registro de paginação B/, response.body

    get overtimes_path, params: { q: @range, page: 2 }
    assert_no_match /Registro de paginação B/, response.body
    assert_select "table tbody tr", count: 5
  end

  test "no pager and no sentinel when everything fits on one page" do
    sign_in users(:one)
    get overtimes_path, params: { q: {
      start_at_gteq: @month.beginning_of_month.to_s,
      start_at_lteq: (@month.beginning_of_month + 2.days).to_s
    } }

    assert_select "table tbody tr", count: 3
    assert_select "nav[aria-label='Paginação']", count: 0
    assert_select "#overtime-sentinel", count: 0
  end

  test "summary totals the whole filtered period, not just the visible page" do
    sign_in users(:one)
    get overtimes_path, params: { q: @range }

    # 25 fixtures x 30 minutes = 12.5h, even though the page shows 20.
    assert_match "12,5h", response.body
  end

  test "turbo stream request appends next page cards and drops the sentinel on the last page" do
    sign_in users(:one)
    get overtimes_path, params: { q: @range, page: 2 },
                        headers: { Accept: "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_select "turbo-stream[action=append][target=overtimes-mobile-list] template div.rounded-lg", count: 5
    assert_select "turbo-stream[action=append][target=overtimes-mobile-list] template #overtime-sentinel", count: 0
    assert_select "turbo-stream[action=remove][target=overtime-sentinel]"
  end

  test "turbo stream request for a stale page beyond the last one appends nothing" do
    sign_in users(:one)
    get overtimes_path, params: { q: @range, page: 3 },
                        headers: { Accept: "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_select "turbo-stream[action=append]", count: 0
    assert_select "turbo-stream[action=remove][target=overtime-sentinel]"
  end

  test "turbo-stream negotiated request without a page param renders the HTML page" do
    # Regression: Turbo form submissions (create/update/destroy redirects)
    # accept turbo-stream, so their redirect follow hits index as TURBO_STREAM
    # with no page param. It must render the HTML page (flash + navigation),
    # not the infinite-scroll stream.
    sign_in users(:one)
    get overtimes_path, params: { q: @range },
                        headers: { Accept: "text/vnd.turbo-stream.html, text/html" }

    assert_response :success
    assert_select "turbo-stream", count: 0
    assert_select "table tbody tr", count: 20
  end
end
