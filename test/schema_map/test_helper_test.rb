# frozen_string_literal: true

require "test_helper"
require "schema_map/test_helper"

class SchemaMap::TestHelperTest < ActiveSupport::TestCase
  include SchemaMap::TestHelper

  test "assert_data_model_map_current passes on a current block and fails with the diff on a stale one" do
    with_target_file("<!-- data-model:begin -->\n<!-- data-model:end -->\n") do |config, path|
      SchemaMap.write!(config)
      assert_data_model_map_current(config)

      File.write(path, File.read(path).sub("**User**", "**Person**"))
      error = assert_raises(Minitest::Assertion) { assert_data_model_map_current(config) }
      assert_includes error.message, "+- **User**"
      assert_includes error.message, "bin/rails agents:data_model"
    end
  end
end
