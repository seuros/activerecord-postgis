# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in active_record-postgis.gemspec
gemspec

gem "rake", "~> 13.0"

rails_version = ENV["RAILS_VERSION"] || "8.1.1"
gem "railties", "~> #{rails_version}"
gem "rails", "~> #{rails_version}"
# Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
gem "rubocop-rails-omakase", require: false

gem "sqlite3", "~> 2.0"

gem "ruby-lsp", "~> 0.23.23", group: :development
