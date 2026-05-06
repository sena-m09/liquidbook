# frozen_string_literal: true

module Liquidbook
  module Tags
    # Shopify Liquid 互換のため標準 Liquid::Render を上書きする。
    # 標準 Liquid は第1引数にクォート付き文字列リテラルしか受け付けないが、
    # Shopify テーマでは {% render block %} のように変数（section.blocks の要素など）を
    # 渡してアプリブロックを動的描画する慣習があるため、変数参照も受け入れる。
    class RenderTag < Liquid::Render
      # 第1キャプチャを QuotedString OR 変数参照（block, section.blocks[0] 等）の OR に拡張する。
      # 後続のキャプチャインデックスを標準 Liquid::Render::SYNTAX と揃える必要があるため、
      # 全体の括弧構造は変えない。
      RELAXED_SYNTAX = /
        (#{Liquid::QuotedString}+|#{Liquid::VariableSignature}+)
        (\s+(with|for)\s+(#{Liquid::QuotedFragment}+))?
        (\s+(?:as)\s+(#{Liquid::VariableSegment}+))?
      /ox

      def lax_parse(markup)
        unless markup =~ RELAXED_SYNTAX
          raise Liquid::SyntaxError, options[:locale].t("errors.syntax.render")
        end

        template_name = Regexp.last_match(1)
        with_or_for   = Regexp.last_match(3)
        variable_name = Regexp.last_match(4)

        @alias_name         = Regexp.last_match(6)
        @variable_name_expr = variable_name ? parse_expression(variable_name) : nil
        @template_name_expr = parse_expression(template_name)
        @is_for_loop        = (with_or_for == "for")

        @attributes = {}
        markup.scan(Liquid::TagAttributes) do |key, value|
          @attributes[key] = parse_expression(value)
        end
      end

      def render_tag(context, output)
        template_name = resolve_template_name(context)

        case template_name
        when String
          render_partial(template_name, context, output)
        when Liquid::Drop, Hash
          # liquidbook はテーマプレビュー用途で app block の実体
          # （インストール済みアプリの snippet）を持たないため、
          # block オブジェクトが渡された場合は type を残すコメントのみ出力する。
          type = template_name["type"] if template_name.respond_to?(:[])
          output << "<!-- render block: type=#{type} -->"
        else
          output << "<!-- render: cannot resolve template name -->"
        end

        output
      end

      private

      def resolve_template_name(context)
        expr = @template_name_expr
        expr.is_a?(String) ? expr : context.evaluate(expr)
      end

      # 標準 Liquid::Render#render_tag の String 用ロジックを再実装している。
      # super 経由にすると @template_name_expr の一時差し替えが必要になり、
      # マルチスレッド下で同一 Tag インスタンスが共有された際に競合するため避けている。
      def render_partial(template_name, context, output)
        partial = Liquid::PartialCache.load(
          template_name,
          context: context,
          parse_context: parse_context
        )

        context_variable_name = @alias_name || template_name.split("/").last

        render_partial_func = lambda do |var, forloop|
          inner_context = context.new_isolated_subcontext
          inner_context.template_name = partial.name
          inner_context.partial = true
          inner_context["forloop"] = forloop if forloop

          @attributes.each do |key, value|
            inner_context[key] = context.evaluate(value)
          end
          inner_context[context_variable_name] = var unless var.nil?
          partial.render_to_output_buffer(inner_context, output)
          forloop&.send(:increment!)
        end

        variable = @variable_name_expr ? context.evaluate(@variable_name_expr) : nil
        if @is_for_loop && variable.respond_to?(:each) && variable.respond_to?(:count)
          forloop = Liquid::ForloopDrop.new(template_name, variable.count, nil)
          variable.each { |var| render_partial_func.call(var, forloop) }
        else
          render_partial_func.call(variable, nil)
        end
      end
    end
  end
end
