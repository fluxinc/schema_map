# frozen_string_literal: true

require "test_helper"

class SchemaMap::CheckTest < ActiveSupport::TestCase
  def current_document(config)
    "<!-- data-model:begin -->\n#{SchemaMap::Map.new(config).render}<!-- data-model:end -->\n"
  end

  test "passes when the committed block matches the generated map" do
    with_target_file("") do |config, path|
      File.write(path, current_document(config))
      result = SchemaMap::Check.new(config).call
      assert result.ok?
      assert_equal :current, result.status
    end
  end

  test "fails with a readable diff and the fix command when a line was hand-edited" do
    with_target_file("") do |config, path|
      File.write(path, current_document(config).sub("**User** (users)", "**User** (people)"))
      result = SchemaMap::Check.new(config).call
      refute result.ok?
      assert_equal :stale, result.status
      assert_includes result.diff, "-- **User** (people)"
      assert_includes result.diff, "+- **User** (users)"
      assert_includes result.message, "bin/rails agents:data_model"
      assert_includes result.message, path
    end
  end

  test "fails without rewriting the file" do
    with_target_file("") do |config, path|
      File.write(path, current_document(config).sub("**User**", "**Person**"))
      before = File.read(path)
      SchemaMap::Check.new(config).call
      assert_equal before, File.read(path)
    end
  end

  test "reports missing markers as a failure rather than raising" do
    with_target_file("nothing here\n") do |config|
      result = SchemaMap::Check.new(config).call
      refute result.ok?
      assert_equal :missing, result.status
      assert_includes result.message, "schema_map:install"
    end
  end

  test "SchemaMap.write! then SchemaMap.check round-trips" do
    with_target_file("<!-- data-model:begin -->\n<!-- data-model:end -->\n") do |config|
      assert SchemaMap.write!(config)
      refute SchemaMap.write!(config), "second write must be a no-op"
      assert SchemaMap.check(config).ok?
    end
  end
end
