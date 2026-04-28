# frozen_string_literal: true

module Liquidbook
  # Analyzes Liquid templates by walking the AST to detect external variable dependencies.
  #
  # Usage:
  #   analyzer = TemplateAnalyzer.new(template_source)
  #   analyzer.external_variables
  #   # => [{ name: "title", lookups: [] }, { name: "product", lookups: ["name"] }]
  class TemplateAnalyzer
    def initialize(source)
      @source = source
    end

    def external_variables
      clean_source = strip_schema(@source)
      template = Liquid::Template.parse(clean_source)
      vars = []
      scope = Scope.new

      template.root.nodelist&.each { |node| walk(node, vars, scope) }

      vars.uniq
    end

    def section_variable?(var)
      var[:name] == "section"
    end

    private

    # Tracks local variables with proper scoping for for-loops.
    # Uses a parent chain so child scopes see parent locals,
    # while scoped variables (loop vars) don't leak upward.
    class Scope
      def initialize(parent = nil)
        @parent = parent
        @locals = []
      end

      def add_local(name)
        @locals << name
      end

      def local?(name)
        @locals.include?(name) || @parent&.local?(name) || false
      end

      def child_with(extra_locals)
        child = Scope.new(self)
        extra_locals.each { |l| child.add_local(l) }
        child
      end
    end

    SCHEMA_REGEX = /\{%-?\s*schema\s*-?%\}.*?\{%-?\s*endschema\s*-?%\}/m

    def strip_schema(source)
      source.gsub(SCHEMA_REGEX, "")
    end

    def walk(node, vars, scope)
      case node
      when Liquid::Variable
        collect_variable(node, vars, scope)
      when Liquid::For
        walk_for(node, vars, scope)
        return
      when Liquid::Assign
        scope.add_local(node.instance_variable_get(:@to).to_s)
      when Liquid::Capture
        scope.add_local(node.instance_variable_get(:@to).to_s)
      when Liquid::If
        walk_if(node, vars, scope)
        return
      end

      walk_nodelist(node, vars, scope)
    end

    def walk_for(node, vars, scope)
      coll = node.collection_name
      add_lookup(vars, coll, scope) if coll.is_a?(Liquid::VariableLookup)

      inner_scope = scope.child_with([node.variable_name, "forloop"])
      node.nodelist&.each { |child| walk(child, vars, inner_scope) }

      else_block = node.instance_variable_get(:@else_block)
      else_block&.nodelist&.each { |child| walk(child, vars, scope) }
    end

    def walk_if(node, vars, scope)
      node.blocks.each do |condition|
        walk_condition(condition, vars, scope)
        condition.attachment&.nodelist&.each { |child| walk(child, vars, scope) }
      end
    end

    def walk_condition(condition, vars, scope)
      return unless condition

      left = condition.left
      right = condition.right
      add_lookup(vars, left, scope) if left.is_a?(Liquid::VariableLookup)
      add_lookup(vars, right, scope) if right.is_a?(Liquid::VariableLookup)

      child = condition.child_condition
      walk_condition(child, vars, scope) if child
    end

    def collect_variable(node, vars, scope)
      vl = node.is_a?(Liquid::Variable) ? node.name : nil
      add_lookup(vars, vl, scope) if vl.is_a?(Liquid::VariableLookup)

      return unless node.is_a?(Liquid::Variable)

      node.filters&.each do |_name, args, kwargs|
        args&.each { |a| add_lookup(vars, a, scope) if a.is_a?(Liquid::VariableLookup) }
        kwargs&.each_value { |v| add_lookup(vars, v, scope) if v.is_a?(Liquid::VariableLookup) }
      end
    end

    def add_lookup(vars, lookup, scope)
      return unless lookup.is_a?(Liquid::VariableLookup)
      return if scope.local?(lookup.name)

      vars << { name: lookup.name, lookups: lookup.lookups }
    end

    def walk_nodelist(node, vars, scope)
      return unless node.respond_to?(:nodelist)

      node.nodelist&.each { |child| walk(child, vars, scope) }
    end
  end
end
