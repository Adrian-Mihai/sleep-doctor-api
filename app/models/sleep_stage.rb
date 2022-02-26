class SleepStage < ApplicationRecord
  enum stage: { awaken: 1, light_sleep: 2, deep_sleep: 3, rem: 4 }

  AWAKEN = 1
  LIGHT_SLEEP = 2
  DEEP_SLEEP = 3
  REM = 4

  validates :uuid, presence: true, uniqueness: true
  validates :start_time, presence: true
  validates :end_time, presence: true

  belongs_to :sleep_session
end
