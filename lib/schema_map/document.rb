# frozen_string_literal: true

module SchemaMap
  # Reads and rewrites the marked block inside the target file. Never touches anything outside the markers.
  class Document
    def initialize(config)
      @config = config
    end

    def path
      @config.file_path
    end

    # The text between the markers (exclusive), or raises MarkersMissing.
    def current_body
      locate(read)[:body]
    end

    # Replace the block body. Returns true when the file content changed.
    def write(body)
      content = read
      found = locate(content)
      updated = content[0...found[:body_start]] + body + content[found[:body_end]..]
      return false if updated == content

      File.write(path, updated)
      true
    end

    private

    def read
      raise MarkersMissing, missing_message("does not exist") unless File.file?(path)

      File.read(path)
    end

    def locate(content)
      begin_marker = @config.begin_marker
      end_marker = @config.end_marker
      begin_count = content.scan(begin_marker).size
      end_count = content.scan(end_marker).size
      unless begin_count == 1 && end_count == 1
        raise MarkersMissing, missing_message("must contain exactly one #{begin_marker} and one #{end_marker} (found #{begin_count} and #{end_count})")
      end

      begin_at = content.index(begin_marker)
      end_at = content.index(end_marker)
      raise MarkersMissing, missing_message("has #{end_marker} before #{begin_marker}") if end_at < begin_at

      body_start = begin_at + begin_marker.length
      body_start += 1 if content[body_start] == "\n"
      { body_start: body_start, body_end: end_at, body: content[body_start...end_at] }
    end

    def missing_message(problem)
      "schema_map: #{path} #{problem}. Run `bin/rails generate schema_map:install` to establish the block."
    end
  end
end
