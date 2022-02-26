class Value < ApplicationRecord
  validates :uuid, presence: true, uniqueness: true
  validates :start_time, presence: true
  validates :end_time, presence: true

  belongs_to :user
end
