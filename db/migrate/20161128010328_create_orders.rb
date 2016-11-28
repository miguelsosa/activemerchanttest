class CreateOrders < ActiveRecord::Migration[5.0]
  def change
    create_table :orders do |t|
      t.belongs_to :customer, foreign_key: true
      t.integer :amount_in_cents
      t.string :description

      t.timestamps
    end
  end
end
