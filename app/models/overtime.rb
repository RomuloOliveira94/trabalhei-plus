class Overtime < ApplicationRecord
  include Discard::Model

  # Discard deliberately ships no default scope; SPEC R11 requires every
  # listing/export to hide discarded rows, so default to `kept` here.
  # Use `.with_discarded` to bypass (e.g. auditing, undiscard flows).
  default_scope -> { kept }
  # Discard's plain `discarded` scope would be cancelled out by the
  # `kept` default scope above, so unscope before filtering.
  scope :discarded, -> { with_discarded.where.not(discarded_at: nil) }

  belongs_to :user

  validates :start_at, :end_at, presence: true
  validates :description, presence: true, length: { maximum: 2000 }

  validate :end_at_after_start_at
  validate :duration_at_least_5_minutes

  scope :for_user, ->(user) { where(user_id: user.id) }
  # Inclusive on both ends. Accepts (from, to) or an open-ended `from`
  # when called via Ransack with a single-side range.
  scope :within_period, ->(from, to = nil) { where(start_at: from..to) }
  scope :chronological, -> { order(start_at: :asc) }

  MINIMUM_DURATION_MINUTES = 5

  # Whole minutes between start and end (negative when end < start).
  def duration_minutes
    return 0 unless start_at && end_at

    ((end_at - start_at) / 60).to_i
  end

  # Decimal hours for UI display ("10,5h" via pt-BR locale, SPEC R12).
  def duration_hours_decimal
    (duration_minutes / 60.0).round(2)
  end

  # Zero-padded "HH:MM" for exports (SPEC R13).
  def duration_formatted_export
    total_minutes = duration_minutes.negative? ? 0 : duration_minutes
    format("%02d:%02d", total_minutes / 60, total_minutes.modulo(60))
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[ start_at end_at description user_id ]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[ user ]
  end

  def self.ransackable_scopes(auth_object = nil)
    %i[ within_period ]
  end

  private

  def end_at_after_start_at
    return unless start_at && end_at

    return if end_at > start_at

    errors.add(:end_at, :after_start_at)
  end

  def duration_at_least_5_minutes
    return unless start_at && end_at
    # Ordering errors are reported by end_at_after_start_at instead.
    return if end_at <= start_at

    if end_at - start_at < MINIMUM_DURATION_MINUTES.minutes
      errors.add(:end_at, :minimum_duration, count: MINIMUM_DURATION_MINUTES)
    end
  end
end
