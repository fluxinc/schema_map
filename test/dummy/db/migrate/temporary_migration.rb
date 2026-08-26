# frozen_string_literal: true

class TemporaryMigration < ActiveRecord::Migration[8.1]
  class MigrationUser < ActiveRecord::Base
    self.table_name = "users"
  end
end
