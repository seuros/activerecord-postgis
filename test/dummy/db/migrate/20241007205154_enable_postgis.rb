# frozen_string_literal: true

class EnablePostgis < ActiveRecord::Migration[7.2]
  def up
    enable_extension "postgis"
  end
end
