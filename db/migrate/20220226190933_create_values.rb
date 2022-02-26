class CreateValues < ActiveRecord::Migration[6.1]
  def change
    create_table :values do |t|
      t.string :uuid, null: false, index: { unique: true }
      t.belongs_to :user, foreign_key: true
      t.string :type, null: false
      t.datetime :start_time, null: false, precision: 6
      t.integer :min, null: false
      t.integer :average, null: false
      t.integer :max, null: false
      t.datetime :end_time, null: false, precision: 6
      t.jsonb :payload

      t.timestamps
    end
  end
end
