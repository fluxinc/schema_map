# frozen_string_literal: true

module SchemaMap
  class Railtie < Rails::Railtie
    config.schema_map = ActiveSupport::OrderedOptions.new

    initializer "schema_map.configure" do |app|
      SchemaMap.configuration.root ||= app.root
      app.config.schema_map.each { |key, value| SchemaMap.configuration.public_send("#{key}=", value) }
    end

    rake_tasks do
      load File.expand_path("../tasks/schema_map.rake", __dir__)
    end
  end
end
