class CreateProducts < ActiveRecord::Migration[5.1]
  def change
    create_table :products do |t|
      t.integer :product_id, null: false
      t.integer :price, null: false
      t.string :name

      t.timestamps
    end
  end
end
