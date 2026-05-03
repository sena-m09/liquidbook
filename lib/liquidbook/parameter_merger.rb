# frozen_string_literal: true

module Liquidbook
  # Merges auto-detected template variables (from TemplateAnalyzer) with
  # type/default/description metadata from @param comments (ParamParser).
  #
  # Variables with @param get their declared type/default/description.
  # Variables without @param are type-inferred from filters and control structures
  # (e.g. money → number, for-loop → array, truthy if → checkbox).
  # When inference is inconclusive, type falls back to "unknown".
  # Section variables (name == "section") are excluded.
  #
  # Usage:
  #   merger = ParameterMerger.new(
  #     variables:  analyzer.external_variables,
  #     param_defs: param_parser.parse
  #   )
  #   merger.merge
  #   # => [{ "name" => "title", "type" => "text", "default" => "My Card", "description" => "Card heading" },
  #   #     { "name" => "color", "type" => "unknown", "default" => nil, "description" => nil }]
  class ParameterMerger
    def initialize(variables:, param_defs:)
      @variables  = variables
      @param_defs = param_defs
    end

    def merge
      @variables
        .reject { |var| section_variable?(var) }
        .map { |var| resolve(var) }
        .uniq { |p| p["name"] }
    end

    private

    def resolve(var)
      name = var[:name].to_s
      param_index[name] || inferred(var)
    end

    def param_index
      @param_index ||= @param_defs.each_with_object({}) do |p, h|
        h[p["name"]] = p
      end
    end

    def section_variable?(var)
      var[:name].to_s == "section"
    end

    def inferred(var)
      name = var[:name].to_s
      type = infer_type(var)
      { "name" => name, "type" => type, "default" => nil, "description" => nil }
    end

    def infer_type(var)
      properties = var[:properties] || []

      return "array" if properties.any? { |p| p[:collection] }
      return "checkbox" if properties.any? { |p| p[:truthy_condition] } && all_filters_empty?(properties)

      all_filters = properties.flat_map { |p| p[:filters] }.uniq
      FilterTypeMap.infer(all_filters) || "unknown"
    end

    def all_filters_empty?(properties)
      properties.all? { |p| p[:filters].empty? }
    end
  end
end
