# frozen_string_literal: true

require "json"

module Liquidbook
  # Extracts and parses {% schema %} blocks from section files
  class SchemaParser
    SCHEMA_REGEX = /\{%-?\s*schema\s*-?%\}(.*?)\{%-?\s*endschema\s*-?%\}/m

    def initialize(template_source)
      @source = template_source
    end

    def parse
      match = @source.match(SCHEMA_REGEX)
      return {} unless match

      JSON.parse(match[1].strip)
    rescue JSON::ParserError => e
      warn "Warning: Failed to parse schema JSON: #{e.message}"
      {}
    end

    # Returns the template source with the schema block removed
    def template_without_schema
      @source.gsub(SCHEMA_REGEX, "").strip
    end

    # Builds default settings values from schema
    def default_settings
      schema = parse
      settings = schema.fetch("settings", [])

      settings.each_with_object({}) do |setting, hash|
        hash[setting["id"]] = setting["default"] if setting["id"]
      end
    end

    # Builds default block data from schema
    def default_blocks
      schema = parse
      blocks = schema.fetch("blocks", [])

      blocks.filter_map do |block|
        next unless block["type"]

        settings = (block["settings"] || []).each_with_object({}) do |s, h|
          h[s["id"]] = s["default"] if s["id"]
        end

        {
          "type" => block["type"],
          "settings" => settings
        }
      end
    end
  end
end
