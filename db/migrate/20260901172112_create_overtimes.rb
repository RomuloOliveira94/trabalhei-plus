class CreateOvertimes < ActiveRecord::Migration[8.1]
  def change
    create_table :overtimes do |t|
      t.references :user, null: false, foreign_key: true
      t.datetime :start_at, null: false
      t.datetime :end_at, null: false
      t.text :description, null: false, default: ""
      t.datetime :discarded_at

      t.timestamps
    end

    # Range queries per user (default month filter, SPEC §9).
    add_index :overtimes, [ :user_id, :start_at ]
    # Soft-delete lookups (discard gem keeps no default scope of its own).
    add_index :overtimes, :discarded_at
  end
end
