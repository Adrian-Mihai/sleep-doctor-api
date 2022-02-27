class SleepStage < ApplicationRecord
  enum stage: { Awaken: 1, 'Light Sleep': 2, 'Deep Sleep': 3, REM: 4 }

  AWAKEN = 1
  LIGHT_SLEEP = 2
  DEEP_SLEEP = 3
  REM = 4

  validates :uuid, presence: true, uniqueness: true
  validates :start_time, presence: true
  validates :end_time, presence: true

  belongs_to :sleep_session
end
