class CreateValues < ActiveRecord::Migration[6.1]
  def change
    create_table :values do |t|
      t.string :uuid, null: false, index: { unique: true }
      t.belongs_to :user, foreign_key: true
      t.string :type, null: false
      t.datetime :start_time, null: false, precision: 6
      t.float :min, null: false
      t.float :mean, null: false
      t.float :max, null: false
      t.datetime :end_time, null: false, precision: 6
      t.jsonb :payload

      t.timestamps
    end
  end
end
