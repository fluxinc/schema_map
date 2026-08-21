# frozen_string_literal: true

require "test_helper"
require "rake"

class SchemaMap::RakeTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?("agents:data_model")
    Rake::Task.tasks.each(&:reenable)
    @schema_path = File.join(Dir.mktmpdir("schema_map_schema"), "schema.rb")
    ENV["SCHEMA"] = @schema_path
  end

  teardown do
    ENV.delete("SCHEMA")
  end

  test "defines the contract task names" do
    assert Rake::Task.task_defined?("agents:data_model")
    assert Rake::Task.task_defined?("agents:data_model:check")
  end

  test "agents:data_model writes the block" do
    with_target_file("<!-- data-model:begin -->\n<!-- data-model:end -->\n") do |config, path|
      SchemaMap.instance_variable_set(:@configuration, config)
      capture_io { Rake::Task["agents:data_model"].invoke }
      assert_includes File.read(path), "- **Tenant** (tenants)"
    end
  end

  test "agents:data_model:check exits 1 when stale and 0 when current" do
    with_target_file("<!-- data-model:begin -->\nstale\n<!-- data-model:end -->\n") do |config|
      SchemaMap.instance_variable_set(:@configuration, config)
      error = nil
      capture_io { error = assert_raises(SystemExit) { Rake::Task["agents:data_model:check"].invoke } }
      assert_equal 1, error.status

      SchemaMap.write!(config)
      Rake::Task["agents:data_model:check"].reenable
      capture_io { assert_nothing_raised { Rake::Task["agents:data_model:check"].invoke } }
    end
  end

  test "db:schema:dump regenerates the block" do
    with_target_file("<!-- data-model:begin -->\nstale\n<!-- data-model:end -->\n") do |config, path|
      SchemaMap.instance_variable_set(:@configuration, config)
      capture_io { Rake::Task["db:schema:dump"].invoke }
      assert File.exist?(@schema_path), "schema should have been dumped"
      assert_includes File.read(path), "- **Tenant** (tenants)"
    end
  end

  test "db:schema:dump fails loudly when the target file has no markers" do
    with_target_file("no markers\n") do |config|
      SchemaMap.instance_variable_set(:@configuration, config)
      error = nil
      _out, err = capture_io { error = assert_raises(SystemExit) { Rake::Task["db:schema:dump"].invoke } }
      assert_equal 1, error.status
      assert_includes err, "schema_map:install"
    end
  end

  test "agents:data_model exits 1 with the message instead of a traceback when refused" do
    with_target_file("no markers\n") do |config|
      SchemaMap.instance_variable_set(:@configuration, config)
      error = nil
      _out, err = capture_io { error = assert_raises(SystemExit) { Rake::Task["agents:data_model"].invoke } }
      assert_equal 1, error.status
      assert_includes err, "exactly one"
    end
  end
end
