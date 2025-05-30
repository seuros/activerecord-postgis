# frozen_string_literal: true

require "rgeo"

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      module Type
        class Spatial < ::ActiveRecord::Type::Value
          attr_reader :geo_type, :srid, :has_z, :has_m, :geographic

          def initialize(geo_type: "geometry", srid: 0, has_z: false, has_m: false, geographic: false)
            @geo_type = geographic ? "geography" : geo_type
            @srid = srid
            @has_z = has_z
            @has_m = has_m
            @geographic = geographic
            @factory = RGeo::ActiveRecord::SpatialFactoryStore.instance.factory(
              geo_type: @geo_type.underscore,
              srid: srid,
              has_z: has_z,
              has_m: has_m,
              sql_type: (@geographic ? "geography" : "geometry")
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
            if binary_string?(string)
              # Parse WKB (Well-Known Binary) format
              wkb_parser = RGeo::WKRep::WKBParser.new(@factory, support_ewkb: true, default_srid: @srid)
              wkb_parser.parse(string)
            else
              # Parse WKT (Well-Known Text) format
              wkt_parser = RGeo::WKRep::WKTParser.new(@factory, support_ewkt: true, default_srid: @srid)
              wkt_parser.parse(string)
            end
          rescue RGeo::Error::ParseError
            nil
          end

          def binary_string?(string)
            string[0] == "\x00" || string[0] == "\x01" || string[0, 4] =~ /[0-9a-fA-F]{4}/
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
