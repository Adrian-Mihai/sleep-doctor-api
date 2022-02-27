class CreateExercises < ActiveRecord::Migration[6.1]
  def change
    create_table :exercises do |t|
      t.string :uuid, null: false, index: { unique: true }
      t.belongs_to :user, foreign_key: true
      t.datetime :start_time, null: false, precision: 6
      t.integer :exercise_type, null: false
      t.integer :duration, null: false
      t.float :burned_calorie, null: false
      t.float :min_heart_rate, null: false
      t.float :mean_heart_rate, null: false
      t.float :max_heart_rate, null: false
      t.datetime :end_time, null: false, precision: 6

      t.timestamps
    end
  end
end
