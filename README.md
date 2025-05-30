# ActiveRecord::PostGIS

**The next-generation PostGIS adapter for Rails** - clean, modern, and built for the future.

## Why This Gem?

This is the **next-generation PostGIS adapter** that brings PostGIS support to Rails the right way:

✅ **Use standard `postgres://` URLs** - No custom adapter names, no special configuration  
✅ **No monkey patching** - Clean extensions using Rails 8 patterns  
✅ **No obscure hacks** - Transparent, well-documented implementation  
✅ **Latest APIs** - Built for Rails 8+ and Ruby 3.3+  
✅ **Zero configuration** - Just add the gem and it works  

Unlike legacy PostGIS adapters that require custom database URLs, special configurations, and complex setup, this gem **extends the existing PostgreSQL adapter** seamlessly. Your database configuration stays clean and standard.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'activerecord-postgis'
```

And then execute:

```
$ bundle install
```

Or install it yourself as:

```
$ gem install activerecord-postgis
```

## Configuration

**Zero configuration required!** Just use your standard PostgreSQL database configuration:

```yaml
# config/database.yml
development:
  adapter: postgresql
  url: postgres://user:password@localhost/myapp_development
  # That's it! No special adapter, no custom configuration
```

## Usage

### Migrations

Create spatial columns using PostGIS types:

```ruby
class CreateLocations < ActiveRecord::Migration[8.0]
  def change
    create_table :locations do |t|
      t.st_point :coordinates, srid: 4326
      t.st_polygon :boundary, geographic: true
      t.st_line_string :route, has_z: true
      t.timestamps
    end
  end
end
```

### Spatial Queries

**With RGeo Objects** (Recommended):

```ruby
# Create RGeo geometries
factory = RGeo::Geographic.spherical_factory(srid: 4326)
point = factory.point(-5.923647, 35.790897)  # Cap Spartel, Tangier, Morocco
polygon = factory.polygon(...)

# Direct queries with RGeo objects
Location.where(coordinates: point)
Location.where("ST_Distance(coordinates, ?) < ?", point, 1000)

# Using parameterized queries (automatically quoted)
locations_nearby = Location.where(
  "ST_DWithin(coordinates, ?, ?)", 
  point, 
  1000  # meters
)

# Complex spatial queries
parks_in_city = Park.where(
  "ST_Within(boundary, ?)", 
  city_polygon
)
```

**With Arel Spatial Methods**:

```ruby
# Find locations within distance
Location.where(
  Location.arel_table[:coordinates].st_distance(point).lt(1000)
)

# Find polygons that contain a point
Boundary.where(
  Boundary.arel_table[:area].st_contains(Arel.spatial(point))
)

# Calculate lengths and areas
Route.select(
  Route.arel_table[:path].st_length.as('distance')
)
```

**With WKT Strings**:

```ruby
# Using Well-Known Text format
Location.where(
  "ST_Distance(coordinates, ST_GeomFromText(?)) < ?",
  "POINT(-5.923647 35.790897)",
  1000
)
```

### Model Integration

```ruby
class Location < ApplicationRecord
  # Works automatically - no configuration needed
  # Spatial attributes are automatically parsed and serialized
end

location = Location.create!(
  coordinates: "POINT(-5.923647 35.790897)"  # Tangier, Morocco
)

puts location.coordinates.x  # -5.923647
puts location.coordinates.y  # 35.790897
```

## Features

🌍 **Complete PostGIS Type Support**
- `st_point`, `st_line_string`, `st_polygon` 
- `st_multi_point`, `st_multi_line_string`, `st_multi_polygon`
- `st_geometry_collection`, `st_geography`
- Support for SRID, Z/M dimensions

🔍 **Spatial Query Methods**
- `st_distance`, `st_contains`, `st_within`, `st_length`
- Custom Arel visitor for PostGIS SQL generation
- Seamless integration with ActiveRecord queries

⚡ **Modern Architecture**
- Built on Rails 8 patterns
- Clean module extensions (no inheritance)
- Proper type registration and schema dumping
- Compatible with multi-database setups

🛠️ **Developer Experience**
- Standard `postgres://` URLs
- Works with existing PostgreSQL tools
- Clear error messages and debugging
- Full RGeo integration

## Acknowledgments

This gem builds upon the incredible work of many contributors to the Ruby geospatial ecosystem:

🙏 **RGeo Ecosystem** - The foundation that makes Ruby geospatial possible:
- [RGeo](https://github.com/rgeo/rgeo) originally by Daniel Azuma, currently maintained by Keith Doggett (@keithdoggett) and Ulysse Buonomo (@BuonOmo)
- [RGeo::ActiveRecord](https://github.com/rgeo/rgeo-activerecord) for ActiveRecord integration
- [RGeo::Proj4](https://github.com/rgeo/rgeo-proj4) for coordinate system transformations
- Former maintainer Tee Parham and all contributors who built this ecosystem

🗺️ **PostGIS Pioneers** - Previous PostGIS adapters that paved the way:
- [activerecord-postgis-adapter](https://github.com/rgeo/activerecord-postgis-adapter) by Daniel Azuma and the RGeo team
- All the maintainers and contributors who solved spatial data challenges in Rails

🌍 **PostGIS & GEOS** - The underlying spatial powerhouses:
- PostGIS developers for the amazing spatial database extension
- GEOS contributors for computational geometry
- PostgreSQL team for the solid foundation

This gem exists because of their pioneering work. I'm simply bringing it into the modern Rails era with cleaner patterns and zero configuration.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/seuros/activerecord-postgis.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).