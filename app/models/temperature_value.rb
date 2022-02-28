class TemperatureValue < Value
  validates :min, numericality: true
  validates :mean, numericality: true
  validates :max, numericality: true
end
