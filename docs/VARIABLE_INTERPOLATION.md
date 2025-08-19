# Variable Interpolation in PostGIS Queries

## Summary

This gem experiences the same variable interpolation issue as [activerecord-postgis-adapter issue #431](https://github.com/rgeo/activerecord-postgis-adapter/issues/431). Additionally, we've incorporated the fix from [PR #422](https://github.com/rgeo/activerecord-postgis-adapter/pull/422) to properly handle RGeo objects as bind parameters using EWKB format to preserve SRID.

## The Issue

When using ActiveRecord's query placeholders (`?`) inside PostGIS string literals, they are incorrectly converted to PostgreSQL's numbered placeholders (`$1`, `$2`, etc.), causing PostGIS to fail parsing the geometry.

### Example of the Problem

```ruby
# This WILL FAIL with "parse error - invalid geometry"
Model.where("ST_Distance(lonlat, 'POINT(? ?)') < ?", lon, lat, distance)
# SQL: SELECT * FROM models WHERE ST_Distance(lonlat, 'POINT($1 $2)') < $3
# Error: HINT: "POINT($1" <-- parse error at position 8 within geometry
```

The issue occurs because ActiveRecord blindly replaces all `?` with `$1`, `$2`, etc., even inside string literals where PostGIS expects actual coordinate values.

## Solutions

### 1. Use the Provided Helper Methods (Recommended)

This gem provides safe helper methods that construct queries correctly:

```ruby
# Class methods for queries
Model.where_st_distance(:column, lon, lat, '<', distance)
Model.where_st_dwithin(:column, lon, lat, distance)
Model.where_st_contains(:column, lon, lat)
Model.where_st_within_point(:column, lon, lat)
Model.where_st_intersects(:column, wkt_string)

# For geographic calculations (meters), use geographic: true
Model.where_st_distance(:column, lon, lat, '<', 5000, geographic: true)
```

### 2. Use Scopes (After Including SpatialScopes)

```ruby
class Property < ApplicationRecord
  include ActiveRecord::ConnectionAdapters::PostGIS::SpatialScopes
end

# Then use the scopes
Property.within_distance(:lonlat, lon, lat, 5000, geographic: true)
Property.beyond_distance(:lonlat, lon, lat, 5000, geographic: true)
Property.near(:lonlat, lon, lat, 5000, geographic: true)
Property.containing_point(:polygon_column, lon, lat)
Property.intersecting(:geometry_column, wkt_string)
```

### 3. Manual Workarounds

If you need to write custom queries, avoid placeholders inside geometry strings:

```ruby
# Option A: Use ST_MakePoint (recommended)
Model.where("ST_Distance(lonlat, ST_MakePoint(?, ?)) < ?", lon, lat, distance)

# Option B: Use ST_GeomFromText with string concatenation
point_wkt = "POINT(#{lon} #{lat})"
Model.where("ST_Distance(lonlat, ST_GeomFromText(?, 4326)) < ?", point_wkt, distance)

# Option C: Use RGeo to generate the WKT
point = RGeo::Geographic.spherical_factory.point(lon, lat)
Model.where("ST_Distance(lonlat, ST_GeomFromText(?, 4326)) < ?", point.to_s, distance)
```

## Geographic vs Geometric Calculations

- **Geometric calculations** (default): Distances are in the unit of the coordinate system (usually degrees for SRID 4326)
- **Geographic calculations**: Distances are in meters, calculations account for Earth's curvature

```ruby
# Geometric (degrees)
Model.where_st_distance(:lonlat, lon, lat, '<', 0.1)  # 0.1 degrees

# Geographic (meters)
Model.where_st_distance(:lonlat, lon, lat, '<', 5000, geographic: true)  # 5000 meters
```

## Why This Happens

This is a fundamental limitation of how ActiveRecord/Rails handles parameter substitution. The framework doesn't parse SQL deeply enough to understand that placeholders inside string literals should be treated differently than regular parameters.

The activerecord-postgis-adapter gem (versions 9.0+) has the same issue, as it's inherent to Rails' query building mechanism.

## Best Practices

1. **Always use the helper methods** when working with PostGIS functions that take geometry parameters
2. **Avoid placeholders inside geometry string literals** like `'POINT(? ?)'`
3. **Use ST_MakePoint or ST_GeomFromText** for dynamic point creation
4. **Consider geographic calculations** when working with real-world distances in meters
5. **Include SpatialScopes** in your models for convenient spatial queries

## See Also

- [GitHub Issue #431](https://github.com/rgeo/activerecord-postgis-adapter/issues/431) - Original issue report
- [PostGIS ST_MakePoint Documentation](https://postgis.net/docs/ST_MakePoint.html)
- [PostGIS ST_GeomFromText Documentation](https://postgis.net/docs/ST_GeomFromText.html)