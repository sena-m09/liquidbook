# frozen_string_literal: true

module Liquidbook
  module Tags
    # Handles {% section 'name' %} tags by rendering the referenced section file
    class SectionTag < Liquid::Tag
      SYNTAX = /['"](\w+)['"]/

      def initialize(tag_name, markup, tokens)
        super
        if markup.strip =~ SYNTAX
          @section_name = Regexp.last_match(1)
        else
          raise Liquid::SyntaxError, "Invalid syntax for section tag: #{markup}"
        end
      end

      def render(context)
        theme_root = context.registers[:theme_root] || Liquidbook.root
        section_path = File.join(theme_root, "sections", "#{@section_name}.liquid")

        unless File.exist?(section_path)
          return "<!-- section '#{@section_name}' not found -->"
        end

        source = File.read(section_path)
        parser = SchemaParser.new(source)
        template = Liquid::Template.parse(parser.template_without_schema, environment: Liquidbook.environment)
        template.render(context)
      end
    end
  end
end
