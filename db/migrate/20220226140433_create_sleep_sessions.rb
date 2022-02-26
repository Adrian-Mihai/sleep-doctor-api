class CreateSleepSessions < ActiveRecord::Migration[6.1]
  def change
    create_table :sleep_sessions do |t|
      t.string :uuid, null: false, index: { unique: true }
      t.belongs_to :user, foreign_key: true
      t.datetime :start_time, null: false, precision: 6
      t.integer :mental_recovery, null: false
      t.integer :physical_recovery, null: false
      t.integer :efficiency, null: false
      t.integer :score, null: false
      t.integer :cycle, null: false
      t.integer :duration, null: false
      t.datetime :end_time, null: false, precision: 6

      t.timestamps
    end
  end
end
