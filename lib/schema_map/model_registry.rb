# frozen_string_literal: true

module SchemaMap
  # Finds the application's concrete Active Record models, deterministically ordered.
  class ModelRegistry
    def initialize(config)
      @config = config
    end

    def models
      eager_load!
      ActiveRecord::Base.descendants
        .reject(&:abstract_class?)
        .select { |model| defined_under_root?(model) }
        .select { |model| model.table_exists? }
        .reject { |model| excluded_table?(model.table_name) }
        .sort_by(&:name)
    end

    private

    def eager_load!
      Rails.application.eager_load! if defined?(Rails) && Rails.respond_to?(:application) && Rails.application
    end

    def defined_under_root?(model)
      return false if model.name.nil?

      location = Object.const_source_location(model.name)&.first
      location && location.start_with?(@config.root_path.to_s)
    end

    def excluded_table?(table_name)
      Array(@config.excluded_tables).any? { |pattern| File.fnmatch?(pattern.to_s, table_name) }
    end
  end
end
