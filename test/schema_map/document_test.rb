# frozen_string_literal: true

require "test_helper"

class SchemaMap::DocumentTest < ActiveSupport::TestCase
  BEFORE = "# Brief\n\nIntro.\n\n<!-- data-model:begin -->\nold\n<!-- data-model:end -->\n\n## After\n"

  test "reads the current block body" do
    with_target_file(BEFORE) do |config|
      assert_equal "old\n", SchemaMap::Document.new(config).current_body
    end
  end

  test "replaces only the block between markers and reports a change" do
    with_target_file(BEFORE) do |config, path|
      assert SchemaMap::Document.new(config).write("new\n")
      assert_equal "# Brief\n\nIntro.\n\n<!-- data-model:begin -->\nnew\n<!-- data-model:end -->\n\n## After\n", File.read(path)
    end
  end

  test "does not touch the file when the block is already current" do
    with_target_file(BEFORE) do |config, path|
      mtime = File.mtime(path)
      refute SchemaMap::Document.new(config).write("old\n")
      assert_equal mtime, File.mtime(path)
    end
  end

  test "raises a clear error when the file is missing" do
    with_target_file(nil) do |config, path|
      error = assert_raises(SchemaMap::MarkersMissing) { SchemaMap::Document.new(config).write("x\n") }
      assert_includes error.message, path
      assert_includes error.message, "schema_map:install"
    end
  end

  test "raises when markers are absent, duplicated, or out of order" do
    [ "no markers\n",
      "<!-- data-model:begin -->\na\n<!-- data-model:end -->\n<!-- data-model:begin -->\n<!-- data-model:end -->\n",
      "<!-- data-model:end -->\n<!-- data-model:begin -->\n" ].each do |content|
      with_target_file(content) do |config|
        assert_raises(SchemaMap::MarkersMissing) { SchemaMap::Document.new(config).current_body }
      end
    end
  end

  test "honours custom markers" do
    content = "<!-- m:start -->\nbody\n<!-- m:stop -->\n"
    with_target_file(content, begin_marker: "<!-- m:start -->", end_marker: "<!-- m:stop -->") do |config|
      assert_equal "body\n", SchemaMap::Document.new(config).current_body
    end
  end
end
