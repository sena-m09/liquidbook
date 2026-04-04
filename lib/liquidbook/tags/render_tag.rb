# frozen_string_literal: true

module Liquidbook
  module Tags
    # Handles {% render 'snippet' %} and {% render 'snippet' with object %}
    # Also handles {% render 'snippet' for collection %}
    class RenderTag < Liquid::Tag
      SYNTAX = /['"]([^'"]+)['"](?:\s+(?:with|for)\s+(\S+)(?:\s+as\s+(\w+))?)?/

      def initialize(tag_name, markup, tokens)
        super
        if markup.strip =~ SYNTAX
          @snippet_name = Regexp.last_match(1)
          @variable_expr = Regexp.last_match(2)
          @alias_name = Regexp.last_match(3)
        else
          # Try simple variable assignments: {% render 'snippet', var: value %}
          if markup.strip =~ /['"]([^'"]+)['"]\s*,?\s*(.*)/
            @snippet_name = Regexp.last_match(1)
            @inline_vars = parse_inline_vars(Regexp.last_match(2))
          else
            raise Liquid::SyntaxError, "Invalid syntax for render tag: #{markup}"
          end
        end
      end

      def render(context)
        theme_root = context.registers[:theme_root] || Liquidbook.root
        snippet_path = find_snippet(theme_root)

        unless snippet_path
          return "<!-- snippet '#{@snippet_name}' not found -->"
        end

        source = File.read(snippet_path)
        template = Liquid::Template.parse(source, environment: Liquidbook.environment)

        # Build isolated scope
        inner = {}

        if @variable_expr
          value = context[@variable_expr]
          alias_key = @alias_name || @snippet_name
          inner[alias_key] = value
        end

        if @inline_vars
          @inline_vars.each do |key, expr|
            inner[key] = context[expr] || expr
          end
        end

        # Merge parent assigns with inner scope
        parent_assigns = {}
        context.environments.each { |env| parent_assigns.merge!(env) if env.is_a?(Hash) }
        assigns = parent_assigns.merge(inner)

        template.render(
          assigns,
          registers: { theme_root: theme_root }
        )
      end

      private

      def find_snippet(theme_root)
        paths = [
          File.join(theme_root, "snippets", "#{@snippet_name}.liquid"),
          File.join(theme_root, "sections", "#{@snippet_name}.liquid")
        ]
        paths.find { |p| File.exist?(p) }
      end

      def parse_inline_vars(str)
        return {} if str.nil? || str.strip.empty?

        vars = {}
        str.scan(/(\w+)\s*:\s*([^,]+)/) do |key, value|
          vars[key.strip] = value.strip.gsub(/\A['"]|['"]\z/, "")
        end
        vars
      end
    end
  end
end
