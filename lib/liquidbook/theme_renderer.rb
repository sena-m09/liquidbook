# frozen_string_literal: true

module Liquidbook
  # Renders a Liquid template with mock data and Shopify-compatible tags/filters
  class ThemeRenderer
    def initialize(theme_root: nil)
      @theme_root = theme_root || Liquidbook.root
      @mock_data = MockData.new(theme_root: @theme_root)
    end

    # Render a section file by name
    def render_section(name, overrides: {})
      path = File.join(@theme_root, "sections", "#{name}.liquid")
      raise Error, "Section not found: #{name}" unless File.exist?(path)

      source = File.read(path)
      render_source(source, section: true, overrides: overrides)
    end

    # Render a snippet file by name, with optional parameter overrides
    def render_snippet(name, overrides: {})
      path = File.join(@theme_root, "snippets", "#{name}.liquid")
      raise Error, "Snippet not found: #{name}" unless File.exist?(path)

      source = File.read(path)
      render_source(source, section: false, snippet_params: snippet_defaults(source).merge(overrides))
    end

    # Render raw Liquid source
    def render_source(source, section: false, snippet_params: {}, overrides: {})
      parser = SchemaParser.new(source)
      template_source = parser.template_without_schema

      assigns = if section
                  @mock_data.with_section(parser)
                else
                  @mock_data.to_assigns
                end

      # Merge snippet @param defaults
      assigns.merge!(snippet_params)

      # Merge any overrides from the UI
      assigns.merge!(overrides)

      template = Liquid::Template.parse(template_source, environment: Liquidbook.environment)
      template.render(
        assigns,
        registers: { theme_root: @theme_root }
      )
    end

    # Extract merged parameter definitions for a snippet.
    # Combines TemplateAnalyzer auto-detected variables with @param metadata.
    def snippet_params(name)
      path = File.join(@theme_root, "snippets", "#{name}.liquid")
      return [] unless File.exist?(path)

      merged_params(File.read(path))
    end

    # List available sections
    def sections
      list_templates("sections")
    end

    # List available snippets
    def snippets
      list_templates("snippets")
    end

    private

    def snippet_defaults(source)
      merged_params(source).each_with_object({}) do |param, hash|
        next if param["type"] == "unknown"

        hash[param["name"]] = param["default"]
      end
    end

    def merged_params(source)
      variables  = TemplateAnalyzer.new(source).external_variables
      param_defs = ParamParser.new(source).parse
      ParameterMerger.new(variables: variables, param_defs: param_defs).merge
    end

    def list_templates(dir)
      pattern = File.join(@theme_root, dir, "*.liquid")
      Dir.glob(pattern).map { |f| File.basename(f, ".liquid") }.sort
    end
  end
end
