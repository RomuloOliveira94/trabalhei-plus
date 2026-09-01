require "test_helper"

class OvertimeTest < ActiveSupport::TestCase
  test "valid record" do
    overtime = Overtime.new(
      user: users(:one),
      start_at: Time.zone.local(2026, 9, 1, 18, 0, 0),
      end_at: Time.zone.local(2026, 9, 1, 19, 0, 0),
      description: "Deploy fora do horário"
    )

    assert overtime.valid?
  end

  test "end_at must be strictly after start_at" do
    base = { user: users(:one), description: "Qualquer coisa" }

    overtime = Overtime.new(base.merge(
      start_at: Time.zone.local(2026, 9, 1, 18, 0, 0),
      end_at: Time.zone.local(2026, 9, 1, 18, 0, 0)
    ))
    assert_not overtime.valid?
    assert overtime.errors.of_kind?(:end_at, :after_start_at)

    overtime.end_at = Time.zone.local(2026, 9, 1, 17, 0, 0)
    assert_not overtime.valid?
    assert overtime.errors.of_kind?(:end_at, :after_start_at)
  end

  test "duration must be at least 5 minutes" do
    base = { user: users(:one), description: "Qualquer coisa" }

    overtime = Overtime.new(base.merge(
      start_at: Time.zone.local(2026, 9, 1, 18, 0, 0),
      end_at: Time.zone.local(2026, 9, 1, 18, 4, 59)
    ))
    assert_not overtime.valid?
    assert overtime.errors.of_kind?(:end_at, :minimum_duration)

    overtime.end_at = Time.zone.local(2026, 9, 1, 18, 5, 0)
    assert overtime.valid?
  end

  test "ordering errors take precedence over duration errors" do
    overtime = Overtime.new(
      user: users(:one),
      start_at: Time.zone.local(2026, 9, 1, 18, 0, 0),
      end_at: Time.zone.local(2026, 9, 1, 17, 0, 0),
      description: "Invertido"
    )

    assert_not overtime.valid?
    assert overtime.errors.of_kind?(:end_at, :after_start_at)
    assert_not overtime.errors.of_kind?(:end_at, :minimum_duration)
  end

  test "description is required and bounded" do
    overtime = Overtime.new(
      user: users(:one),
      start_at: Time.zone.local(2026, 9, 1, 18, 0, 0),
      end_at: Time.zone.local(2026, 9, 1, 19, 0, 0),
      description: ""
    )
    assert_not overtime.valid?
    assert overtime.errors.of_kind?(:description, :blank)

    overtime.description = "a" * 2001
    assert_not overtime.valid?
    assert overtime.errors.of_kind?(:description, :too_long)
  end

  test "start_at and end_at are required" do
    overtime = Overtime.new(user: users(:one), description: "Sem datas")

    assert_not overtime.valid?
    assert overtime.errors.of_kind?(:start_at, :blank)
    assert overtime.errors.of_kind?(:end_at, :blank)
  end

  test "discard hides the record from the default scope but keeps the row" do
    overtime = overtimes(:one)

    assert_changes -> { overtime.reload.discarded_at }, from: nil do
      overtime.discard!
    end

    assert Overtime.with_discarded.exists?(overtime.id)
    assert_not Overtime.exists?(overtime.id)
    assert_not Overtime.kept.exists?(overtime.id)
    assert Overtime.discarded.exists?(overtime.id)
  end

  test "undiscard brings the record back" do
    overtimes(:discarded).undiscard!

    assert Overtime.kept.exists?(overtimes(:discarded).id)
  end

  test "duration_minutes is an integer of whole minutes" do
    overtime = Overtime.new(
      start_at: Time.zone.local(2026, 9, 1, 18, 0, 0),
      end_at: Time.zone.local(2026, 9, 1, 19, 30, 30)
    )

    assert_equal 90, overtime.duration_minutes
  end

  test "duration_hours_decimal rounds to two decimals" do
    overtime = Overtime.new(
      start_at: Time.zone.local(2026, 9, 1, 18, 0, 0),
      end_at: Time.zone.local(2026, 9, 1, 21, 30, 0)
    )

    assert_equal 3.5, overtime.duration_hours_decimal
  end

  test "duration_formatted_export is zero-padded HH:MM" do
    build = lambda do |hours, minutes|
      Overtime.new(
        start_at: Time.zone.local(2026, 9, 1, 0, 0, 0),
        end_at: Time.zone.local(2026, 9, 1, hours, minutes, 0)
      ).duration_formatted_export
    end

    assert_equal "10:30", build.call(10, 30)
    assert_equal "00:05", build.call(0, 5)
    assert_equal "00:00", build.call(0, 0)
  end

  test "within_period is inclusive on both ends" do
    from = Time.zone.local(2026, 9, 1, 8, 0, 0)
    to = Time.zone.local(2026, 9, 30, 23, 59, 59)

    ids = Overtime.within_period(from, to).map(&:id)

    assert_includes ids, overtimes(:one).id
    assert_not_includes ids, overtimes(:previous_month).id
  end

  test "for_user scopes to the given user" do
    assert_equal [ overtimes(:from_bruno).id ], Overtime.for_user(users(:two)).map(&:id)
  end

  test "chronological orders by start_at ascending" do
    ids = Overtime.for_user(users(:one)).chronological.map(&:id)

    assert_equal [ overtimes(:previous_month).id, overtimes(:one).id ], ids
  end

  test "ransackable attributes are explicitly whitelisted" do
    assert_equal %w[ start_at end_at description user_id ], Overtime.ransackable_attributes
    assert_equal %w[ user ], Overtime.ransackable_associations
    assert_equal %i[ within_period ], Overtime.ransackable_scopes
  end

  test "ransack filters by date range and sorts by start_at" do
    month_start = Date.current.beginning_of_month
    ransack = Overtime.ransack(
      "start_at_gteq" => month_start.in_time_zone.beginning_of_day,
      "start_at_lteq" => month_start.end_of_month.in_time_zone.end_of_day,
      "s" => "start_at asc"
    )

    ids = ransack.result.map(&:id)

    assert_includes ids, overtimes(:one).id
    assert_not_includes ids, overtimes(:previous_month).id
    assert_not_includes ids, overtimes(:discarded).id
  end

  test "ransack within_period scope accepts a from/to pair" do
    month_start = Date.current.beginning_of_month
    ransack = Overtime.ransack(
      "within_period" => [ month_start.in_time_zone.beginning_of_day, month_start.end_of_month.in_time_zone.end_of_day ]
    )

    assert_includes ransack.result.map(&:id), overtimes(:one).id
    assert_not_includes ransack.result.map(&:id), overtimes(:previous_month).id
  end
end
