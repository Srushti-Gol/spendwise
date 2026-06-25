class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false, default: ''
      t.string :password_digest, null: false
      t.string :name, null: false
      t.string :role, default: 'staff'
      t.string :department
      t.references :tenant, null: false, foreign_key: true
      t.string :jti, null: false
      t.timestamps
    end
    add_index :users, :email, unique: true
    add_index :users, :jti, unique: true
    add_index :users, [ :tenant_id, :role ]
  end
end
