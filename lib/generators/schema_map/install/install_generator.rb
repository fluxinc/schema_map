# frozen_string_literal: true

require "rails/generators"

module SchemaMap
  module Generators
    # Installs the initializer, the verify-only guard test, the pre-commit hook, and the marked block.
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      class_option :file, type: :string, default: "AGENTS.md", desc: "Target document relative to the app root"
      class_option :ownership_column, type: :string, default: nil, desc: "Column that scopes records to their owner, e.g. case_id"

      HOOK_SIGNATURE = "Installed by schema_map"

      def create_initializer
        template "initializer.rb.tt", "config/initializers/schema_map.rb"
      end

      def create_guard_test
        template "data_model_map_test.rb.tt", "test/config/data_model_map_test.rb"
      end

      def create_pre_commit_hook
        hook = ".githooks/pre-commit"
        existing = File.join(destination_root, hook)
        if File.exist?(existing) && !File.read(existing).include?(HOOK_SIGNATURE)
          say_status :skip, "#{hook} exists and was not written by schema_map; add `bin/rails agents:data_model:check` to it yourself", :yellow
        else
          template "pre-commit.tt", hook
          chmod hook, 0o755
        end
      end

      def establish_block
        path = File.join(destination_root, options[:file])
        content = File.exist?(path) ? File.read(path) : ""
        if content.include?(config.begin_marker) && content.include?(config.end_marker)
          say_status :identical, "#{options[:file]} already carries the data-model markers", :blue
        else
          block = "#{config.begin_marker}\n#{config.end_marker}\n"
          content = content.empty? ? block : "#{content.chomp}\n\n#{block}"
          create_file options[:file], content, force: true
        end
        fill_block
      end

      def explain_hook_path
        say ""
        say "Enable the pre-commit guard in each clone (add this to bin/setup):", :green
        say "  git config core.hooksPath .githooks"
        say "Regenerate with `bin/rails agents:data_model`; verify with `bin/rails agents:data_model:check`."
      end

      private

      def config
        # Models are discovered from the running application; the document lives under the generator destination.
        @config ||= SchemaMap::Configuration.new(
          root: Rails.root, file: File.join(destination_root, options[:file]), ownership_column: options[:ownership_column]
        )
      end

      def fill_block
        SchemaMap.write!(config)
        say_status :generate, "data-model map written into #{options[:file]}", :green
      rescue StandardError => e
        say_status :skip, "could not render the map now (#{e.class}: #{e.message}); run `bin/rails agents:data_model` once the database is available", :yellow
      end
    end
  end
end
