# frozen_string_literal: true

module SchemaMap
  class Configuration
    DEFAULT_EXCLUDED_TABLES = %w[
      active_storage_attachments
      active_storage_blobs
      active_storage_variant_records
    ].freeze

    # root: application root; models defined outside it (engines, gems) are not mapped.
    # file: target document, absolute or relative to root.
    # ownership_column: the column that scopes records to their owner (e.g. "case_id"); nil omits the owner segment.
    # command: the regenerate command shown in the header and in failure messages.
    attr_accessor :root, :file, :begin_marker, :end_marker, :excluded_tables, :ownership_column, :command

    def initialize(root: nil, file: "AGENTS.md", begin_marker: "<!-- data-model:begin -->",
                   end_marker: "<!-- data-model:end -->", excluded_tables: DEFAULT_EXCLUDED_TABLES.dup,
                   ownership_column: nil, command: "bin/rails agents:data_model")
      @root = root
      @file = file
      @begin_marker = begin_marker
      @end_marker = end_marker
      @excluded_tables = excluded_tables
      @ownership_column = ownership_column
      @command = command
    end

    def root_path
      Pathname.new((root || (defined?(Rails) && Rails.respond_to?(:root) && Rails.root) || Dir.pwd).to_s)
    end

    def file_path
      root_path.join(file.to_s)
    end

    def check_command
      "#{command}:check"
    end
  end
end
