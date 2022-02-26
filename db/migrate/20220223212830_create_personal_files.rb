class CreatePersonalFiles < ActiveRecord::Migration[6.1]
  def change
    create_table :personal_files do |t|
      t.string :uuid, null: false, index: { unique: true }
      t.belongs_to :user, foreign_key: true
      t.string :type, null: false
      t.integer :status, null: false, default: 0

      t.timestamps
    end
  end
end
