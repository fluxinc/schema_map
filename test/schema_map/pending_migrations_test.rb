# frozen_string_literal: true

require "test_helper"
require "rake"

class SchemaMap::PendingMigrationsTest < ActiveSupport::TestCase
  setup do
    @migrations_dir = Dir.mktmpdir("schema_map_migrations")
    File.write(File.join(@migrations_dir, "20200101000000_pending_probe.rb"), <<~RUBY)
      class PendingProbe < ActiveRecord::Migration[7.1]
        def change; end
      end
    RUBY
    @original_paths = ActiveRecord::Migrator.migrations_paths
    ActiveRecord::Migrator.migrations_paths = [ @migrations_dir ]
  end

  teardown do
    ActiveRecord::Migrator.migrations_paths = @original_paths
    FileUtils.rm_rf(@migrations_dir)
  end

  test "detects pending migrations" do
    assert SchemaMap.pending_migrations?
  end

  test "write! refuses with a clear message while migrations are pending" do
    with_target_file("<!-- data-model:begin -->\nold\n<!-- data-model:end -->\n") do |config, path|
      error = assert_raises(SchemaMap::PendingMigrations) { SchemaMap.write!(config) }
      assert_includes error.message, "pending migrations"
      assert_includes error.message, "db:migrate"
      assert_equal "<!-- data-model:begin -->\nold\n<!-- data-model:end -->\n", File.read(path), "file must be untouched"
    end
  end

  test "check reports pending migrations as a failure without raising" do
    with_target_file("<!-- data-model:begin -->\nold\n<!-- data-model:end -->\n") do |config|
      result = SchemaMap.check(config)
      refute result.ok?
      assert_equal :pending_migrations, result.status
      assert_includes result.message, "pending migrations"
    end
  end

  test "the schema dump enhancement still regenerates, because the dump mirrors the live database" do
    with_target_file("<!-- data-model:begin -->\nold\n<!-- data-model:end -->\n") do |config, path|
      assert SchemaMap.write!(config, allow_pending_migrations: true)
      assert_includes File.read(path), "- **Tenant** (tenants)"
    end
  end
end
