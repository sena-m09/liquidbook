# frozen_string_literal: true

require "yaml"

module Liquidbook
  # Loads .liquid-preview/config.yml from the theme root
  #
  # head entries can be:
  #   - Raw HTML:  <script src="https://cdn.tailwindcss.com"></script>
  #   - File path: ../src-lit/styles/main.css
  #   - File path: ./src/components.js
  #
  # File paths are resolved relative to the theme root and served via /__imports__/
  class Config
    DEFAULT_CONFIG = {
      "head" => [],
      "port" => 4567,
      "host" => "127.0.0.1"
    }.freeze

    IMPORT_PATH_PREFIX = "/__imports__"

    def initialize(theme_root: nil)
      @theme_root = theme_root || Liquidbook.root
      @data = load_config
    end

    # Returns HTML strings ready to inject into <head>
    def head_tags_html
      Array(@data["head"]).map { |entry| entry_to_html(entry) }
    end

    # Returns a map of serve_path => absolute_file_path for file imports
    def import_files
      @import_files ||= build_import_map
    end

    def port
      @data["port"] || 4567
    end

    def host
      @data["host"] || "127.0.0.1"
    end

    def [](key)
      @data[key.to_s]
    end

    private

    def load_config
      path = File.join(@theme_root, ".liquid-preview", "config.yml")
      return DEFAULT_CONFIG.dup unless File.exist?(path)

      loaded = YAML.safe_load(File.read(path), permitted_classes: []) || {}
      DEFAULT_CONFIG.merge(loaded)
    end

    def file_path?(entry)
      # Not raw HTML, looks like a path
      !entry.strip.start_with?("<") && entry.match?(/\.\w+$/)
    end

    def resolve_path(entry)
      File.expand_path(entry.strip, @theme_root)
    end

    def serve_path(entry)
      # Use resolved absolute path for a deterministic, safe URL
      abs = resolve_path(entry)
      safe_name = abs.gsub(/[^a-zA-Z0-9._-]/, "_")
      "#{IMPORT_PATH_PREFIX}/#{safe_name}"
    end

    def entry_to_html(entry)
      if file_path?(entry)
        url = serve_path(entry)
        ext = File.extname(entry.strip).downcase
        case ext
        when ".css"
          %(<link rel="stylesheet" href="#{url}">)
        when ".js", ".mjs", ".ts"
          %(<script type="module" src="#{url}"></script>)
        else
          %(<link href="#{url}">)
        end
      else
        entry.strip
      end
    end

    def build_import_map
      map = {}
      Array(@data["head"]).each do |entry|
        next unless file_path?(entry)

        abs = resolve_path(entry)
        map[serve_path(entry)] = abs
      end
      map
    end
  end
end
