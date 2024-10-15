# frozen_string_literal: true

class CreateUser < ActiveRecord::Migration[7.2]
  def change
    enable_extension "uuid-ossp"

    create_table :users, id: :uuid do |t|
      t.string :name

      t.timestamps
    end
  end
end
