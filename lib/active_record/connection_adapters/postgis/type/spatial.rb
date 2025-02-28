# frozen_string_literal: true

require "rgeo"

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      module Type
        class Spatial < ::ActiveRecord::Type::Value
          attr_reader :geo_type, :srid, :has_z, :has_m

          def initialize(geo_type: "geometry", srid: 0, has_z: false, has_m: false)
            @geo_type = geo_type
            @srid = srid
            @has_z = has_z
            @has_m = has_m
            @factory = RGeo::ActiveRecord::SpatialFactoryStore.instance.factory(
              geo_type: geo_type,
              srid: srid,
              has_z_coordinate: has_z,
              has_m_coordinate: has_m
            )
          end

          def type
            :geometry
          end

          def serialize(value)
            if value.respond_to?(:as_text)
              "SRID=#{value.srid};#{value.as_text}"
            elsif value.is_a?(String)
              value
            else
              super
            end
          end

          private

          def cast_value(value)
            case value
            when ::RGeo::Feature::Instance
              value
            when String
              parse_wkt(value)
            when Hash
              parse_hash(value)
            else
              nil
            end
          end

          def parse_wkt(string)
            if string =~ /^SRID=(\d+);(.+)/
              srid = $1.to_i
              wkt = $2
              RGeo::Geos.factory(srid: srid).parse_wkt(wkt)
            else
              @factory.parse_wkt(string)
            end
          rescue RGeo::Error::ParseError
            nil
          end

          def parse_hash(hash)
            # Support GeoJSON-style hash
            if hash["type"] && hash["coordinates"]
              RGeo::GeoJSON.decode(hash.to_json, geo_factory: @factory)
            else
              nil
            end
          end
        end
      end
    end
  end
end
