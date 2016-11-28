class CreateCards < ActiveRecord::Migration[5.0]
  def change
    create_table :cards do |t|
      t.belongs_to :customer, foreign_key: true
      t.string :last4
      t.bigint :profile_id

      t.timestamps
    end
  end
end
