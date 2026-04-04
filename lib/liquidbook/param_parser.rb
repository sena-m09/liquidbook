# frozen_string_literal: true

module Liquidbook
  # Extracts @param comments from snippet files to build editable parameter forms
  #
  # Supported format:
  #   @param {Type} name - description
  #   @param {Type} name [default_value] - description
  class ParamParser
    PARAM_REGEX = /@param\s+\{(\w+)\}\s+(\w+)(?:\s+\[([^\]]*)\])?\s*(?:-\s*(.*))?/

    def initialize(source)
      @source = source
    end

    def parse
      @source.scan(PARAM_REGEX).map do |type, name, default, description|
        {
          "name" => name,
          "type" => normalize_type(type),
          "default" => coerce_default(type, default),
          "description" => description&.strip
        }
      end
    end

    # Build assigns hash from params with their defaults
    def default_assigns
      parse.each_with_object({}) do |param, hash|
        hash[param["name"]] = param["default"]
      end
    end

    private

    def normalize_type(type)
      case type.downcase
      when "string" then "text"
      when "number", "integer", "int", "float" then "number"
      when "boolean", "bool" then "checkbox"
      when "object", "hash" then "json"
      when "array" then "json"
      else "text"
      end
    end

    def coerce_default(type, value)
      return sample_value(type) if value.nil? || value.strip.empty?

      case type.downcase
      when "string" then value.strip
      when "number", "integer", "int" then value.strip.to_i
      when "float" then value.strip.to_f
      when "boolean", "bool" then %w[true 1 yes].include?(value.strip.downcase)
      else value.strip
      end
    end

    # Provide sensible sample values when no default is given
    def sample_value(type)
      case type.downcase
      when "string" then "Sample Text"
      when "number", "integer", "int" then 1
      when "float" then 1.0
      when "boolean", "bool" then false
      else "sample"
      end
    end
  end
end
