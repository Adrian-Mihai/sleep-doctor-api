class SleepSession < ApplicationRecord
  MINIMUM_SLEEP_DURATION = 4

  validates :uuid, presence: true, uniqueness: true
  validates :start_time, presence: true
  validates :mental_recovery, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :physical_recovery, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :efficiency, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :score, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :cycle, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :duration, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :start_time, presence: true

  validate :minimum_sleep_duration

  has_many :sleep_stages, dependent: :destroy

  belongs_to :user

  accepts_nested_attributes_for :sleep_stages

  private

  def minimum_sleep_duration
    return if duration.nil?

    errors.add(:duration, "must be at least #{MINIMUM_SLEEP_DURATION} hours") unless duration >= MINIMUM_SLEEP_DURATION * 60
  end
end
