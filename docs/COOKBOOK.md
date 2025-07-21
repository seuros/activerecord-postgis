# 🚀 The Starship Navigator's Guide to PostGIS

> "In space, nobody can hear you SELECT. But they can see your ship's trajectory, calculate intercept courses, and determine if you're within photon torpedo range." — Captain Jean-Luc PostgreSQL, FSS Marseille

## 🎯 Mission Briefings

1. [The Fleet Command Center](#the-fleet-command-center)
2. [The Planetary Defense Grid](#the-planetary-defense-grid)
3. [The Hyperspace Route Calculator](#the-hyperspace-route-calculator)
4. [The Galactic Territory Registry](#the-galactic-territory-registry)
5. [The Subspace Proximity Scanner](#the-subspace-proximity-scanner)

---

## The Fleet Command Center

*Your starships are scattered across the galaxy like atoms in the void. Time to coordinate their movements with military precision.*

### The Quantum Leap: K-Nearest Neighbor Search

The `<->` operator is your secret weapon for finding the nearest anything at warp speed:

```ruby
# app/models/starship.rb
class Starship < ApplicationRecord
  # Find nearest starships using KNN (blazing fast with spatial index!)
  scope :nearest_to, ->(position, limit = 10) {
    order(arel_table[:current_coordinates].distance_operator(position))
      .limit(limit)
  }
  
  # Combine KNN with distance calculations when you need actual distances
  scope :nearest_with_distances, ->(position, limit = 10) {
    select(
      "*",
      "ST_Distance(current_coordinates, ST_GeomFromText('#{position.as_text}', 4326)) as distance_meters"
    )
    .order(arel_table[:current_coordinates].distance_operator(position))
    .limit(limit)
  }
  
  # Emergency protocols: Find nearest friendly ships
  def nearest_allies(count = 5)
    self.class
      .where(faction: faction)
      .where.not(id: id)
      .order(
        self.class.arel_table[:current_coordinates].distance_operator(current_coordinates)
      )
      .limit(count)
  end
  
  # Tactical assessment: Nearest threats
  def incoming_threats(scan_limit = 20)
    HostileVessel
      .active
      .select(
        "*",
        "ST_Distance(position, ST_GeomFromText('#{current_coordinates.as_text}', 4326)) as threat_distance"
      )
      .order(
        HostileVessel.arel_table[:position].distance_operator(current_coordinates)
      )
      .limit(scan_limit)
      .having("threat_distance < ?", sensor_range)
  end
end

# The Navigation AI notes:
# "Traditional distance queries are like checking every star in the galaxy.
#  The <-> operator is like having a sorted list already waiting for you.
#  Always use <-> for 'find nearest' queries—your CPU will thank you."
```

```ruby
# app/models/starship.rb
class Starship < ApplicationRecord
  # Find ships within warp range of a space station
  scope :in_range_of, ->(space_station, max_distance_parsecs = 10) {
    where(status: 'operational')
      .where(
        arel_table[:current_coordinates].st_dwithin(
          space_station.location,
          max_distance_parsecs * 3.086e16  # Convert parsecs to meters
        )
      )
      .order(
        Arel.sql("ST_Distance(current_coordinates, ST_GeomFromText('#{space_station.location.as_text}', 4326))")
      )
  }

  # Check if ship is in any hostile territory (asteroid fields, nebula, etc)
  def in_hostile_space?
    HostileZone.active.exists?(
      HostileZone.arel_table[:boundary].st_contains(current_coordinates)
    )
  end

  # Calculate effective sensor range
  def sensor_perimeter(range_km = 100_000)
    self.class
      .select("*, ST_Buffer(current_coordinates::geography, #{range_km * 1000})::geometry as sensor_coverage")
      .find(id)
  end
end

# The Fleet Admiral advises:
# "A ship 9.9 parsecs away might seem closer than one 10.1 parsecs away,
#  but if the first must navigate the Maelstrom Nebula,
#  the second ship is your salvation."
```

---

## The Planetary Defense Grid

*Every planet needs a defense perimeter. Every star system needs boundaries. But only the wise know how to monitor them across light-years of space.*

```ruby
# app/models/defense_perimeter.rb
class DefensePerimeter < ApplicationRecord
  # Chainable scope for finding all perimeters containing a ship
  scope :containing_vessel, ->(ship_position) {
    where(arel_table[:shield_boundary].st_contains(ship_position))
  }

  # Find overlapping defense grids (potential shield interference)
  scope :interfering_with, ->(other_perimeter) {
    where.not(id: other_perimeter.id)
      .where(arel_table[:shield_boundary].st_intersects(other_perimeter.shield_boundary))
  }

  # Create an extended shield bubble around critical installations
  def emergency_shield_extension(extension_km = 10_000)
    DefensePerimeter.create!(
      name: "#{name} - Emergency Shield Extension",
      shield_boundary: shield_boundary.st_buffer(extension_km * 1000),
      perimeter_type: 'emergency_shield',
      parent_id: id
    )
  end

  # Monitoring: Alert when hostile vessels approach
  def hostile_vessels_detected(warning_distance_km = 50_000)
    HostileVessel
      .active
      .where.not(
        HostileVessel.arel_table[:position].st_within(shield_boundary)
      )
      .where(
        HostileVessel.arel_table[:position].st_dwithin(shield_boundary, warning_distance_km * 1000)
      )
  end
end

# app/models/tracked_vessel.rb
class TrackedVessel < ApplicationRecord
  # Defense perimeter events
  def entered_perimeters
    DefensePerimeter.containing_vessel(position) - DefensePerimeter.containing_vessel(previous_position)
  end

  def breached_perimeters
    DefensePerimeter.containing_vessel(previous_position) - DefensePerimeter.containing_vessel(position)
  end
end

# Tactical Log Entry:
# "The best defense grid is one you never detect until your shields are already failing.
#  The second best is one that immediately alerts Starfleet Command."
```

---

## The Hyperspace Route Calculator

*Hyperspace routes tell stories. Some are legendary shortcuts through the cosmos. Others are cautionary tales of ships lost in subspace.*

```ruby
# app/models/hyperspace_route.rb
class HyperspaceRoute < ApplicationRecord
  # Find routes that pass through specific sectors
  scope :traversing_sector, ->(sector) {
    where(arel_table[:jump_path].st_intersects(sector))
  }

  # Analyze hyperspace efficiency
  def jump_efficiency_analysis
    {
      total_jump_distance: calculate_jump_distance,
      realspace_distance: straight_line_distance,
      hyperspace_coefficient: straight_line_distance / calculate_jump_distance,
      sectors_crossed: sectors_traversed.count,
      gravity_wells_encountered: gravity_wells_near_path.count,
      estimated_fuel_cost: calculate_antimatter_consumption
    }
  end

  def calculate_jump_distance
    self.class
      .where(id: id)
      .pluck(Arel.sql("ST_Length(#{arel_table[:jump_path].to_sql}::geography)"))
      .first
  end

  def straight_line_distance
    return 0 unless jump_path.num_points >= 2
    
    start_point = jump_path.point_n(0)
    end_point = jump_path.point_n(jump_path.num_points - 1)
    
    self.class
      .select(
        Arel.sql("ST_Distance(ST_GeomFromText('#{start_point.as_text}', 4326)::geography, ST_GeomFromText('#{end_point.as_text}', 4326)::geography) as distance")
      )
      .first
      .distance
  end

  def sectors_traversed
    GalacticSector.where(GalacticSector.arel_table[:boundary].st_intersects(jump_path))
  end

  def gravity_wells_near_path
    # Stars and black holes that could affect hyperspace travel
    CelestialBody
      .massive
      .where(
        CelestialBody.arel_table[:gravity_field].st_dwithin(jump_path, 1.0e15)  # 1 light-year safety margin
      )
  end

  # Find alternative jump routes in the same hyperspace corridor
  def alternative_jump_routes(corridor_width_ly = 5)
    corridor_buffer = jump_path.st_buffer(corridor_width_ly * 9.461e15)  # Convert light-years to meters
    
    HyperspaceRoute
      .where.not(id: id)
      .where(arel_table[:jump_path].st_within(corridor_buffer))
      .where(
        "ST_StartPoint(jump_path) = ST_StartPoint(?::geometry) AND ST_EndPoint(jump_path) = ST_EndPoint(?::geometry)",
        jump_path, jump_path
      )
  end

  def calculate_antimatter_consumption
    base_consumption = calculate_jump_distance / 1.0e13  # kg per 10 trillion meters
    gravity_penalty = gravity_wells_near_path.sum(:mass) / 1.0e30  # Solar mass units
    base_consumption * (1 + gravity_penalty * 0.1)
  end
end

# The Hyperspace Navigation Computer declares:
# "The shortest jump is not always the safest.
#  The safest jump is not always the most fuel-efficient.
#  The most fuel-efficient jump is not always possible.
#  But PostGIS calculates them all in subspace-time."
```

---

## The Galactic Territory Registry

*In the game of galactic dominion, you either control your sectors or watch them fall to chaos.*

```ruby
# app/models/star_system_territory.rb
class StarSystemTerritory < ApplicationRecord
  belongs_to :galactic_governor
  
  # Validate no overlapping sovereign space
  validate :no_overlapping_territories

  # Find neighboring star systems
  scope :bordering, ->(territory) {
    where.not(id: territory.id)
      .where(arel_table[:space_boundary].st_touches(territory.space_boundary))
  }

  # Calculate territory metrics in cosmic scale
  def territory_metrics
    area_cubic_parsecs = self.class
      .where(id: id)
      .pluck(
        Arel.sql("ST_Area(#{arel_table[:space_boundary].to_sql}::geography) / #{(3.086e16)**2}")
      )
      .first

    {
      area_cubic_parsecs: area_cubic_parsecs,
      perimeter_light_years: calculate_perimeter_ly,
      inhabited_systems: inhabited_systems_count,
      resource_worlds: resource_worlds_in_territory.count,
      population_billions: calculate_total_population / 1.0e9,
      military_strength: calculate_fleet_strength,
      bordering_empires: self.class.bordering(self).pluck(:galactic_governor_id)
    }
  end

  # Rebalance territories based on strategic value
  def suggest_boundary_adjustment(target_strategic_value)
    current_value = strategic_value_index
    
    if current_value > target_strategic_value
      # Territory too valuable, suggest reduction for balance
      reduction_factor = target_strategic_value / current_value
      suggested_boundary = space_boundary.st_buffer(
        -1.0e15 * (1 - reduction_factor)  # Negative buffer in space units
      )
    else
      # Territory needs more resources, suggest expansion
      expansion_factor = current_value / target_strategic_value
      suggested_boundary = space_boundary.st_buffer(
        1.0e15 * (1 - expansion_factor)
      )
    end

    {
      current_strategic_value: current_value,
      target_strategic_value: target_strategic_value,
      adjustment_type: current_value > target_strategic_value ? :reduce : :expand,
      suggested_boundary: suggested_boundary,
      affected_systems: StarSystem.where(
        StarSystem.arel_table[:coordinates].st_within(suggested_boundary)
      ).count
    }
  end
  
  def strategic_value_index
    base_value = inhabited_systems_count * 100
    base_value += resource_worlds_in_territory.count * 500
    base_value += wormhole_endpoints_controlled * 1000
    base_value * (1 + military_strength / 1000.0)
  end

  private

  def no_overlapping_territories
    overlapping = self.class
      .where.not(id: id)
      .where(galactic_governor_id: galactic_governor_id)
      .where(arel_table[:space_boundary].st_intersects(space_boundary))
      .exists?

    errors.add(:space_boundary, "violates sovereignty of another empire") if overlapping
  end

  def inhabited_systems_count
    StarSystem
      .inhabited
      .where(
        StarSystem.arel_table[:coordinates].st_within(space_boundary)
      )
      .count
  end

  def resource_worlds_in_territory
    Planet
      .where(resource_class: ['dilithium', 'tritanium', 'latinum'])
      .joins(:star_system)
      .where(
        StarSystem.arel_table[:coordinates].st_within(space_boundary)
      )
  end

  def calculate_perimeter_ly
    perimeter_meters = self.class
      .where(id: id)
      .pluck(
        Arel.sql("ST_Perimeter(#{arel_table[:space_boundary].to_sql}::geography)")
      )
      .first
      
    perimeter_meters / 9.461e15  # Convert to light-years
  end

  def calculate_total_population
    inhabited_systems = StarSystem
      .inhabited
      .where(StarSystem.arel_table[:coordinates].st_within(space_boundary))
      
    inhabited_systems.sum(:population)
  end

  def calculate_fleet_strength
    Fleet
      .where(home_territory_id: id)
      .sum(:combat_rating)
  end

  def wormhole_endpoints_controlled
    Wormhole
      .where(
        "ST_Within(endpoint_alpha, ?) OR ST_Within(endpoint_omega, ?)",
        space_boundary, space_boundary
      )
      .count
  end
end

# The Galactic Senate Cartographer proclaims:
# "Perfect territories are like perfect spheres in zero gravity—theoretically elegant, practically impossible.
#  In the cosmos, we balance power, resources, and the ability to defend what we claim."
```

---

## The Subspace Proximity Scanner

*Finding "nearby" in space is relative. Finding "nearby and strategic" wins wars.*

```ruby
# app/models/concerns/subspace_scannable.rb
module SubspaceScannable
  extend ActiveSupport::Concern

  included do
    scope :near, ->(point, distance_meters = 5000) {
      where(
        arel_table[:location].st_dwithin(point, distance_meters)
      )
      .order(
        Arel.sql("ST_Distance(location, ST_GeomFromText('#{point.as_text}', 4326))")
      )
    }

    scope :in_viewport, ->(southwest, northeast) {
      # Create bounding box from corner points
      viewport_polygon = RGeo::Cartesian.factory(srid: 4326).polygon(
        RGeo::Cartesian.factory(srid: 4326).linear_ring([
          southwest,
          factory.point(northeast.x, southwest.y),
          northeast,
          factory.point(southwest.x, northeast.y),
          southwest
        ])
      )
      
      where(arel_table[:location].st_within(viewport_polygon))
    }
  end

  class_methods do
    # K-nearest neighbor search
    def nearest_k(point, k = 10)
      order(
        Arel.sql("location <-> ST_GeomFromText('#{point.as_text}', 4326)")
      ).limit(k)
    end

    # Find clusters of nearby objects
    def find_clusters(distance_threshold = 100)
      sql = <<-SQL
        WITH clusters AS (
          SELECT 
            id,
            location,
            ST_ClusterDBSCAN(location, eps := #{distance_threshold}, minpoints := 2) 
              OVER () AS cluster_id
          FROM #{table_name}
        )
        SELECT * FROM clusters WHERE cluster_id IS NOT NULL
        ORDER BY cluster_id, id
      SQL
      
      connection.execute(sql)
    end
  end

  # Instance methods
  def nearby_friends(radius = 1000)
    self.class
      .where.not(id: id)
      .near(location, radius)
  end

  def isolation_score
    # How far to nearest neighbor?
    nearest = self.class
      .where.not(id: id)
      .nearest_k(location, 1)
      .first
      
    return Float::INFINITY unless nearest
    
    location.st_distance(nearest.location)
  end
end

# Usage example
class Restaurant < ApplicationRecord
  include ProximitySearchable
  
  # Find restaurants with no competition nearby
  scope :monopoly_locations, ->(min_distance = 2000) {
    all.select { |r| r.isolation_score > min_distance }
  }
  
  # Group restaurants by food court/cluster
  def food_court_members
    return [] unless cluster_id
    
    self.class.where(cluster_id: cluster_id).where.not(id: id)
  end
end

# The Search Algorithm whispers:
# "Distance is just a number until you're hungry at 2 AM.
#  Then it becomes destiny."
```

---

## 🎓 The Admiral's Final Transmission

*The Fleet Admiral's hologram flickers to life one last time:*

"You have served well, Navigator. But remember these truths as you traverse the cosmos:

- **Spatial indexes are your warp core** - Without them, you're drifting at sublight speeds
- **SRID consistency is your star chart** - Mix coordinate systems at your peril
- **Buffer zones are your shields** - Size them wisely, for space is vast but danger is near
- **Intersections are hyperspace jump points** - Not all lead where you expect
- **Distance calculations are your fuel gauges** - The universe answers in parsecs or processor cycles

Navigate boldly. May your queries return swiftly and your coordinates be true."

*— Fleet Admiral Tera Byte, Keeper of the Galactic Navigation Archives*

---

## 🚨 Red Alert: When Your Queries Go Supernova

If your spatial queries are moving at sublight speeds, run this diagnostic:

1. **Shield Generator Check**: Did I add the spatial index? (`using: :gist`)
2. **Navigation Alignment**: Am I using the right SRID consistently across all systems?
3. **Efficiency Protocol**: Could I use `st_dwithin` instead of calculating `st_distance`? (It's like using warp drive instead of impulse)
4. **Dimensional Analysis**: Am I storing geography when I need geometry (or vice versa)?
5. **Quantum Debugging**: Have I tried explaining my query plan to the ship's AI?

Remember: In the vast expanse of spatial data, PostGIS is your faster-than-light engine. But even the best warp core can't help if you're feeding it dark matter instead of antimatter.

*"May your geometries be valid, your coordinates be precise, and your queries return before the heat death of the universe."* — Ancient PostgreSQL Prayer, carved into the hull of the first database ship