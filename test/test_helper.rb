# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

require_relative "dummy/config/environment"
require "rails/test_help"
require "minitest/autorun"
require "tmpdir"
require "support/engine_models"

ActiveRecord::Migration.verbose = false
load File.expand_path("dummy/db/schema.rb", __dir__)

module SchemaMapTestSupport
  # Run a block with a fresh configuration whose target file lives in a temp directory.
  def with_target_file(content, **overrides)
    Dir.mktmpdir("schema_map") do |dir|
      path = File.join(dir, "AGENTS.md")
      File.write(path, content) unless content.nil?
      config = SchemaMap::Configuration.new(root: Rails.root, file: path, **overrides)
      yield config, path
    end
  end

  def teardown
    super
    SchemaMap.reset_configuration!
  end
end

class ActiveSupport::TestCase
  include SchemaMapTestSupport
end
