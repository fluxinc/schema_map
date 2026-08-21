# frozen_string_literal: true

module SchemaMap
  # Verifies the committed block against a fresh render without writing anything.
  class Check
    Result = Struct.new(:status, :diff, :message, keyword_init: true) do
      def ok?
        status == :current
      end
    end

    def initialize(config)
      @config = config
    end

    def call
      document = Document.new(@config)
      SchemaMap.ensure_migrated!(@config)
      expected = Map.new(@config).render
      actual = document.current_body
      if actual == expected
        Result.new(status: :current, diff: "", message: "schema_map: #{document.path} data-model map is current.")
      else
        diff = LineDiff.new(actual, expected).to_s
        Result.new(status: :stale, diff: diff, message: stale_message(document.path, diff))
      end
    rescue MarkersMissing => e
      Result.new(status: :missing, diff: "", message: e.message)
    rescue PendingMigrations => e
      Result.new(status: :pending_migrations, diff: "", message: e.message)
    end

    private

    def stale_message(path, diff)
      <<~MSG
        schema_map: the data-model map in #{path} is stale (committed vs generated, -committed +generated):
        #{diff.chomp}
        Run `#{@config.command}` and commit the result.
      MSG
    end

    # Minimal LCS line diff: no runtime dependency on diff-lcs. Emits -/+/space lines with one line of context.
    class LineDiff
      def initialize(old_text, new_text)
        @old = old_text.lines.map(&:chomp)
        @new = new_text.lines.map(&:chomp)
      end

      def to_s
        ops = operations
        keep = Array.new(ops.size, false)
        ops.each_with_index { |(op, _), i| next if op == :same; ((i - 1)..(i + 1)).each { |j| keep[j] = true if j.between?(0, ops.size - 1) } }
        out = []
        ops.each_with_index do |(op, line), i|
          next unless keep[i]
          prefix = { same: " ", del: "-", add: "+" }.fetch(op)
          out << "#{prefix}#{line}"
        end
        out.join("\n") + "\n"
      end

      private

      def operations
        m = @old.size
        n = @new.size
        table = Array.new(m + 1) { Array.new(n + 1, 0) }
        (m - 1).downto(0) do |i|
          (n - 1).downto(0) do |j|
            table[i][j] = @old[i] == @new[j] ? table[i + 1][j + 1] + 1 : [ table[i + 1][j], table[i][j + 1] ].max
          end
        end
        ops = []
        i = j = 0
        while i < m && j < n
          if @old[i] == @new[j]
            ops << [ :same, @old[i] ]
            i += 1
            j += 1
          elsif table[i + 1][j] >= table[i][j + 1]
            ops << [ :del, @old[i] ]
            i += 1
          else
            ops << [ :add, @new[j] ]
            j += 1
          end
        end
        ops.concat(@old[i..].map { |l| [ :del, l ] }) if i < m
        ops.concat(@new[j..].map { |l| [ :add, l ] }) if j < n
        ops
      end
    end
  end
end
