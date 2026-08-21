# frozen_string_literal: true

require "schema_map/version"
require "schema_map/configuration"
require "schema_map/model_registry"
require "schema_map/model_line"
require "schema_map/map"
require "schema_map/document"
require "schema_map/check"
require "schema_map/railtie" if defined?(Rails::Railtie)

# A generated, verified one-line-per-model data-model map kept between markers in AGENTS.md.
module SchemaMap
  class Error < StandardError; end
  class MarkersMissing < Error; end
  class PendingMigrations < Error; end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield configuration
      configuration
    end

    def reset_configuration!
      @configuration = nil
    end

    # Render the block body from Active Record reflection. The map mirrors the live connection, so a
    # database with pending migrations is refused unless the caller knows the schema was just dumped.
    def generate(config = configuration, allow_pending_migrations: false)
      ensure_migrated!(config) unless allow_pending_migrations
      Map.new(config).render
    end

    # Replace the block in the target file. Returns true when the file changed.
    def write!(config = configuration, allow_pending_migrations: false)
      Document.new(config).write(generate(config, allow_pending_migrations: allow_pending_migrations))
    end

    # Compare the committed block with a fresh render without touching the file.
    def check(config = configuration)
      Check.new(config).call
    end

    def pending_migrations?
      ActiveRecord::Migration.check_all_pending!
      false
    rescue ActiveRecord::PendingMigrationError
      true
    end

    def ensure_migrated!(config)
      return unless pending_migrations?

      env = defined?(Rails) && Rails.respond_to?(:env) ? Rails.env : "current"
      raise PendingMigrations, "schema_map: the #{env} database has pending migrations, so the data-model map " \
        "would not match db/schema.rb. Run `bin/rails db:migrate` (which regenerates the map) before `#{config.command}`."
    end
  end
end
