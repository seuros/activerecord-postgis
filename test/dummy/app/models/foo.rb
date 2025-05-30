# frozen_string_literal: true

class Foo < ApplicationRecord
  has_one :spatial_foo
  attribute :bar, :string, array: true
  attribute :baz, :string, range: true
end
