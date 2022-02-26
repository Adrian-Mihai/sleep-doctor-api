class PersonalFile < ApplicationRecord
  enum status: { uploaded: 0, processing: 1, processed: 2 }

  validates :uuid, presence: true, uniqueness: true

  UPLOADED = 0
  PROCESSING = 1
  PROCESSED = 2

  belongs_to :user

  has_one_attached :zip_file, dependent: :purge_later
end
