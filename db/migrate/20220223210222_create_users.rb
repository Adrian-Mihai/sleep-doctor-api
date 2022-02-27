class CreateUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :users do |t|
      t.string :uuid, null: false, index: { unique: true }
      t.string :email, null: false, index: { unique: true }
      t.integer :age, null: false
      t.string :password_digest
      t.boolean :terms_and_conditions, null: false, default: false

      t.timestamps
    end
  end
end
