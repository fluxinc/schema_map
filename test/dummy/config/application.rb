# frozen_string_literal: true

require "rails"
require "active_record/railtie"
require "active_storage/engine"
require "schema_map"

module Dummy
  class Application < Rails::Application
    config.root = File.expand_path("..", __dir__)
    config.load_defaults Rails::VERSION::STRING.to_f
    config.eager_load = false
    config.logger = Logger.new(nil)
    config.active_support.deprecation = :stderr
    config.secret_key_base = "dummy"
    config.active_record.dump_schema_after_migration = true
    config.active_storage.service = :test
  end
end
