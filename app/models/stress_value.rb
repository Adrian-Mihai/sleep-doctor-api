class StressValue < Value
  validates :min, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :mean, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :max, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
end
