class HeartRateValue < Value
  validates :min, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 300 }
  validates :average, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 300 }
  validates :max, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 300 }
end
