class CreateBoards < ActiveRecord::Migration[7.1]
  def change
    create_table :boards do |t|
      t.string :name
      t.datetime :date_created
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
