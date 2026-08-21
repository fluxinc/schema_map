# frozen_string_literal: true

module SchemaMap
  # Renders one model as one Markdown list line.
  class ModelLine
    BOILERPLATE_COLUMNS = %w[created_at updated_at].freeze
    OWNER_SEARCH_DEPTH = 5

    def initialize(model, config, registry_models)
      @model = model
      @config = config
      @registry_models = registry_models
    end

    def render
      "- **#{@model.name}** (#{table_label}) — #{segments.join("; ")}"
    end

    private

    def table_label
      sti_child? ? "#{@model.table_name}; STI < #{@model.superclass.name}" : @model.table_name
    end

    def sti_child?
      !@model.superclass.abstract_class? && @model.superclass < ActiveRecord::Base && @model.superclass.table_name == @model.table_name
    end

    def segments
      [
        association_segment(:belongs_to),
        association_segment(:has_one),
        association_segment(:has_many),
        association_segment(:has_and_belongs_to_many),
        attached_segment,
        concerns_segment,
        columns_segment,
        unique_segment,
        checks_segment,
        owner_segment
      ].compact
    end

    def association_segment(macro)
      reflections = @model.reflect_on_all_associations(macro)
        .reject { |r| attachment_reflection_names.include?(r.name.to_s) }
        .sort_by { |r| r.name.to_s }
      return nil if reflections.empty?

      "#{macro} #{reflections.map { |r| association_label(r) }.join(", ")}"
    end

    def association_label(reflection)
      label = reflection.name.to_s
      if reflection.polymorphic?
        "#{label}*"
      elsif reflection.options[:through]
        "#{label}→#{reflection.options[:through]}"
      elsif reflection.options[:as]
        "#{label}[#{reflection.options[:as]}]"
      else
        label
      end
    end

    # Active Storage declares `<name>_attachment(s)` and `<name>_blob(s)` associations per attachment;
    # they are reported once as `attached <name>` (or `<name>[]` for has_many_attached) instead.
    def attachment_reflections
      @model.respond_to?(:attachment_reflections) ? @model.attachment_reflections : {}
    end

    def attachment_reflection_names
      @attachment_reflection_names ||= attachment_reflections.keys.flat_map do |name|
        [ "#{name}_attachment", "#{name}_blob", "#{name}_attachments", "#{name}_blobs" ]
      end
    end

    def attached_segment
      return nil if attachment_reflections.empty?

      labels = attachment_reflections.sort_by { |name, _| name.to_s }.map do |name, reflection|
        reflection.macro == :has_many_attached ? "#{name}[]" : name.to_s
      end
      "attached #{labels.join(", ")}"
    end

    def concerns_segment
      names = @model.included_modules
        .select { |mod| mod.is_a?(ActiveSupport::Concern) && mod.name && defined_under_root?(mod.name) }
        .map(&:name).sort
      names.empty? ? nil : "concerns #{names.join(", ")}"
    end

    def defined_under_root?(constant_name)
      location = Object.const_source_location(constant_name)&.first
      location && location.start_with?(@config.root_path.to_s)
    end

    def columns_segment
      return nil if sti_child?

      columns = @model.columns
        .reject { |c| c.name == @model.primary_key || BOILERPLATE_COLUMNS.include?(c.name) }
        .sort_by(&:name)
      return nil if columns.empty?

      "cols #{columns.map { |c| column_label(c) }.join(", ")}"
    end

    def column_label(column)
      label = +"#{column.name}:#{column.type}"
      label << "!" unless column.null
      default = scalar_default(column)
      label << "=#{default}" unless default.nil?
      label
    end

    def scalar_default(column)
      return nil if column.default.nil? || column.default_function
      value = @model.attribute_types[column.name]&.deserialize(column.default)
      case value
      when true, false, Integer, Float, BigDecimal then value.to_s
      when String then value.length <= 20 ? value.inspect : nil
      end
    end

    def unique_segment
      return nil if sti_child?

      indexes = @model.connection.indexes(@model.table_name).select(&:unique).sort_by { |i| Array(i.columns).join("+") }
      return nil if indexes.empty?

      "unique #{indexes.map { |i| index_label(i) }.join(", ")}"
    end

    def index_label(index)
      label = +Array(index.columns).join("+")
      label << " where(#{index.where.to_s.squish})" if index.where.present?
      label
    end

    def checks_segment
      return nil if sti_child?

      constraints = @model.connection.check_constraints(@model.table_name)
      return nil if constraints.empty?

      labels = constraints.map { |c| c.name.presence || c.expression.to_s.squish }.sort
      "checks #{labels.join(", ")}"
    end

    def owner_segment
      column = @config.ownership_column.to_s
      return nil if column.empty?
      return "owner self" if "#{@model.model_name.singular}_id" == column
      return "owner #{column}" if @model.column_names.include?(column)

      path = owner_path(@model, column, [], OWNER_SEARCH_DEPTH)
      path ? "owner via #{path.join(".")}.#{column}" : "owner none"
    end

    # Breadth-first walk over non-polymorphic belongs_to associations to the first model carrying the column.
    def owner_path(model, column, trail, depth)
      return nil if depth.zero?

      steps = model.reflect_on_all_associations(:belongs_to).reject(&:polymorphic?).sort_by { |r| r.name.to_s }
      steps.each do |reflection|
        target = safe_klass(reflection)
        next unless target
        return trail + [ reflection.name.to_s ] if target.column_names.include?(column)
      end
      steps.each do |reflection|
        target = safe_klass(reflection)
        next unless target
        found = owner_path(target, column, trail + [ reflection.name.to_s ], depth - 1)
        return found if found
      end
      nil
    end

    def safe_klass(reflection)
      klass = reflection.klass
      klass.table_exists? ? klass : nil
    rescue NameError, ArgumentError
      nil
    end
  end
end
