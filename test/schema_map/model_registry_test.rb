# frozen_string_literal: true

require "test_helper"
require_relative "../dummy/db/migrate/temporary_migration"

class SchemaMap::ModelRegistryTest < ActiveSupport::TestCase
  test "lists non-abstract app models sorted by name" do
    names = SchemaMap::ModelRegistry.new(SchemaMap::Configuration.new(root: Rails.root)).models.map(&:name)
    assert_equal %w[Car Comment Project Task Tenant User Vehicle], names
  end

  test "excludes models defined outside the application root" do
    names = SchemaMap::ModelRegistry.new(SchemaMap::Configuration.new(root: Rails.root)).models.map(&:name)
    refute_includes names, "FakeEngine::Blob"
  end

  test "excludes temporary Active Record classes defined inside migrations" do
    names = SchemaMap::ModelRegistry.new(SchemaMap::Configuration.new(root: Rails.root)).models.map(&:name)
    refute_includes names, "TemporaryMigration::MigrationUser"
  end

  test "excludes configured tables" do
    config = SchemaMap::Configuration.new(root: Rails.root, excluded_tables: %w[vehicles])
    names = SchemaMap::ModelRegistry.new(config).models.map(&:name)
    assert_equal %w[Comment Project Task Tenant User], names
  end

  test "default exclusions are the Active Storage tables" do
    assert_equal %w[active_storage_attachments active_storage_blobs active_storage_variant_records],
      SchemaMap::Configuration.new.excluded_tables
  end
end
