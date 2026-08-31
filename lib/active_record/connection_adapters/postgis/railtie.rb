# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      class Railtie < ::Rails::Railtie
        config.after_initialize do
          PostGIS.ignore_postgis_system_tables
        end
      end
    end
  end
end
