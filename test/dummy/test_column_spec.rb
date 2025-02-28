#!/usr/bin/env ruby
# Test column spec generation

ENV["DATABASE_USER"] = "ubuntu"
ENV["DATABASE_HOST"] = "localhost"
ENV["BUNDLE_GEMFILE"] = File.expand_path("../../Gemfile", __dir__)

require "bundler/setup"
require_relative "config/environment"
require "active_record/schema_dumper"

conn = ActiveRecord::Base.connection
dumper = ActiveRecord::SchemaDumper.new(conn)

# Test a spatial column
col = conn.columns("buildings").find { |c| c.name == "footprint" }
puts "Column: #{col.name}"
puts "SQL Type: #{col.sql_type}"
puts "Type: #{col.type}"

# Use reflection to call column_spec
spec = dumper.send(:column_spec, col)
puts "Column spec: #{spec.inspect}"

# Test formatting
if dumper.respond_to?(:format_column_spec, true)
  formatted = dumper.send(:format_column_spec, spec)
  puts "Formatted: #{formatted}"
end
