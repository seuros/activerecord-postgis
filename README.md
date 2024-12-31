# Activerecord::PostGIS

Activerecord::PostGIS is a Ruby gem that extends the PostgreSQL adapter in Active Record to support PostGIS spatial types and functions.

## Description

This gem enhances the functionality of the PostgreSQL adapter by adding support for PostGIS-specific data types. 
Unlike the PostGIS adapter gem, which provides a separate adapter, Activerecord::PostGIS extends the existing PostgresqlAdapter with the correct types for working with spatial data in PostGIS.

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

## Usage

Once installed, the gem automatically extends the PostgreSQL adapter with PostGIS support. You can use PostGIS data types in your migrations and models without any additional configuration.

Example migration:

```ruby
class AddLocationToPost < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :location, :point
  end
end
```

Example model:

```ruby
class PostalCode < ApplicationRecord
  # No additional configuration needed
end
```

## Features

- Seamless integration with ActiveRecord
- Support for PostGIS data types (e.g., point, linestring, polygon)
- Ability to use spatial queries and functions in your Rails application

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/seuros/activerecord-postgis.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).