class CreateTransactions < ActiveRecord::Migration
  def self.up
    create_table :transactions do |t|
      t.string :source_id
      t.string :source_type
      t.string :target_id
      t.string :target_type

      t.timestamps
    end

    add_index :transactions, :source_id
    add_index :transactions, :target_id
  end

  def self.down
    drop_table :transactions
  end
end
