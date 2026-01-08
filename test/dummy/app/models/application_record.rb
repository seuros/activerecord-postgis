# frozen_string_literal: true

# <rails-lens:schema:begin>
# database_dialect = "PostgreSQL"
# <rails-lens:schema:end>
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end
