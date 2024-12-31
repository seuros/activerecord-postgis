# frozen_string_literal: true

require_relative "postgis/version"
require_relative "postgis/constants"
require_relative "postgis/spatial_column_methods"
require_relative "postgis/spatial_column_type"
require_relative "postgis/schema_dumper"

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
    end
  end
end
