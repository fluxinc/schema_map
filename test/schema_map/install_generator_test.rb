# frozen_string_literal: true

require "test_helper"
require "rails/generators/test_case"
require "generators/schema_map/install/install_generator"

class SchemaMap::InstallGeneratorTest < Rails::Generators::TestCase
  tests SchemaMap::Generators::InstallGenerator
  destination File.join(Dir.tmpdir, "schema_map_generator_#{Process.pid}")
  setup :prepare_destination

  test "installs initializer, guard test, hook, and a filled block in a new AGENTS.md" do
    run_generator

    assert_file "config/initializers/schema_map.rb", /SchemaMap.configure/
    assert_file "test/config/data_model_map_test.rb", /assert_data_model_map_current/
    assert_file ".githooks/pre-commit", /agents:data_model:check/
    assert File.executable?(File.join(destination_root, ".githooks/pre-commit")), "hook must be executable"
    assert_file "AGENTS.md" do |content|
      assert_includes content, "<!-- data-model:begin -->"
      assert_includes content, "- **Tenant** (tenants)"
      assert_includes content, "<!-- data-model:end -->"
    end
  end

  test "appends markers to an existing AGENTS.md without disturbing its content" do
    File.write(File.join(destination_root, "AGENTS.md"), "# Existing brief\n\nKeep me.\n")
    run_generator
    assert_file "AGENTS.md" do |content|
      assert content.start_with?("# Existing brief\n\nKeep me.\n")
      assert_includes content, "<!-- data-model:begin -->"
    end
  end

  test "refuses to overwrite a pre-commit hook it did not write" do
    FileUtils.mkdir_p(File.join(destination_root, ".githooks"))
    File.write(File.join(destination_root, ".githooks/pre-commit"), "#!/bin/sh\necho mine\n")
    output = run_generator
    assert_file ".githooks/pre-commit", /echo mine/
    assert_match(/pre-commit.*exists/i, output)
  end
end
