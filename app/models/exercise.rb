class Exercise < ApplicationRecord
  enum exercise_type: { Walking: 1001, Running: 1002, 'Push-ups': 10004, Burpee: 10010, Squats: 10012,
                        Crunches: 10023, 'Leg-Raises': 10024, Plank: 10025, 'Cycling': 11007 }

  validates :uuid, presence: true, uniqueness: true
  validates :start_time, presence: true
  validates :duration, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :burned_calorie, numericality: { greater_than_or_equal_to: 0 }
  validates :min_heart_rate, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 300 }
  validates :mean_heart_rate, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 300 }
  validates :max_heart_rate, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 300 }
  validates :end_time, presence: true

  belongs_to :user
end
