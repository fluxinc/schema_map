# frozen_string_literal: true

require "schema_map"

module SchemaMap
  # Include in a test case: `assert_data_model_map_current` fails with the diff and fix command when stale.
  module TestHelper
    def assert_data_model_map_current(config = SchemaMap.configuration)
      result = SchemaMap.check(config)
      assert result.ok?, result.message
    end
  end
end
