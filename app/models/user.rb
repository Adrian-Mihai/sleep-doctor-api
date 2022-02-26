class User < ApplicationRecord
  has_secure_password

  validates :uuid, :email, presence: true, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, confirmation: true, length: { minimum: 8 }, if: -> { password.present? }
  validates :terms_and_conditions, inclusion: { in: [true], message: 'must be accepted' }

  has_many :samsung_health_files, dependent: :destroy
  has_many :sleep_sessions, dependent: :destroy
  has_many :heart_rate_values, dependent: :destroy
  has_many :stress_values, dependent: :destroy
end
