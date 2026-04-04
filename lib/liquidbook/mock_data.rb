# frozen_string_literal: true

require "yaml"

module Liquidbook
  # Provides mock Shopify objects for template rendering
  class MockData
    DEFAULT_FIXTURES_PATH = File.expand_path("../../fixtures/default_mocks.yml", __dir__)

    def initialize(theme_root: nil)
      @theme_root = theme_root || Liquidbook.root
      @data = load_data
    end

    def to_assigns
      @data.dup
    end

    # Merge section schema defaults into the data
    def with_section(schema_parser)
      assigns = to_assigns
      assigns["section"] = {
        "settings" => schema_parser.default_settings,
        "blocks" => schema_parser.default_blocks
      }
      assigns
    end

    private

    def load_data
      data = load_yaml(DEFAULT_FIXTURES_PATH)

      # Override with user's custom mocks if present
      user_mocks = File.join(@theme_root, ".liquid-preview", "mocks.yml")
      data = deep_merge(data, load_yaml(user_mocks)) if File.exist?(user_mocks)

      data
    end

    def load_yaml(path)
      return {} unless File.exist?(path)

      YAML.safe_load(File.read(path), permitted_classes: [Date, Time]) || {}
    end

    def deep_merge(base, override)
      base.merge(override) do |_key, old_val, new_val|
        if old_val.is_a?(Hash) && new_val.is_a?(Hash)
          deep_merge(old_val, new_val)
        else
          new_val
        end
      end
    end
  end
end
