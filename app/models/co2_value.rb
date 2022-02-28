class Co2Value < Value
  validates :min, numericality: { greater_than_or_equal_to: 300 }
  validates :mean, numericality: { greater_than_or_equal_to: 300 }
  validates :max, numericality: { greater_than_or_equal_to: 300 }
end
