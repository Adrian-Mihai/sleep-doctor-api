class CreateSleepStages < ActiveRecord::Migration[6.1]
  def change
    create_table :sleep_stages do |t|
      t.string :uuid, null: false, index: { unique: true }
      t.belongs_to :sleep_session, foreign_key: true
      t.datetime :start_time, null: false, precision: 6
      t.integer :stage, null: false
      t.datetime :end_time, null: false, precision: 6

      t.timestamps
    end
  end
end
