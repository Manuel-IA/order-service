class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.integer :customer_id, null: false
      t.string :product_name, null: false
      t.integer :quantity, null: false
      t.decimal :price, null: false, precision: 12, scale: 2
      t.integer :status, null: false, default: 0
      t.string :customer_name
      t.string :address

      t.timestamps
    end

    add_index :orders, :customer_id
    add_index :orders, :status
  end
end
