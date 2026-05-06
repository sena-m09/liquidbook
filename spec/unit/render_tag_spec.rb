# frozen_string_literal: true

require "spec_helper"

RSpec.describe "{% render %} tag" do
  def render_liquid(source, assigns = {})
    template = Liquid::Template.parse(source, environment: Liquidbook.environment)
    template.render(
      assigns,
      registers: {
        theme_root: FIXTURE_THEME,
        file_system: Liquidbook::ThemeFileSystem.new(FIXTURE_THEME)
      }
    )
  end

  describe "basic rendering" do
    it "renders a snippet without arguments" do
      html = render_liquid("{% render 'badge' %}")
      expect(html).to include('<span class="badge">')
    end

    it "renders a snippet with inline key-value params" do
      html = render_liquid("{% render 'badge', label: 'Sale' %}")
      expect(html).to include('<span class="badge">Sale</span>')
    end

    it "renders a snippet with multiple inline params" do
      html = render_liquid("{% render 'card', title: 'Test', price: '500' %}")
      expect(html).to include("<h2>Test</h2>")
    end
  end

  describe "with/as syntax" do
    it "passes a variable with 'with'" do
      html = render_liquid(
        "{% render 'badge' with badge_label as label %}",
        { "badge_label" => "New" }
      )
      expect(html).to include('<span class="badge">New</span>')
    end
  end

  describe "variable reference in params" do
    it "evaluates variable expressions passed as param values" do
      html = render_liquid(
        "{% render 'badge', label: my_label %}",
        { "my_label" => "Dynamic" }
      )
      expect(html).to include('<span class="badge">Dynamic</span>')
    end
  end

  describe "scope isolation" do
    it "does not leak parent variables into the snippet" do
      html = render_liquid(
        "{% render 'badge' %}",
        { "label" => "Leaked" }
      )
      expect(html).to include('<span class="badge"></span>')
    end
  end

  describe "nested snippet rendering" do
    it "passes params to a snippet rendered inside another snippet" do
      html = render_liquid(
        "{% render 'product-card', title: 'Bag', price: '3000', featured: true %}"
      )
      expect(html).to include("Bag")
      expect(html).to include("product-card--featured")
      expect(html).to include('<span class="badge">Featured</span>')
    end

    it "does not render badge when featured is false" do
      html = render_liquid(
        "{% render 'product-card', title: 'Hat', price: '1000', featured: false %}"
      )
      expect(html).to include("Hat")
      expect(html).not_to include("badge")
    end
  end

  describe "error handling" do
    it "renders an error message for a missing snippet" do
      html = render_liquid("{% render 'nonexistent' %}")
      expect(html).to include("Liquid error")
      expect(html).to include("No such template 'nonexistent'")
    end

    it "renders an error for illegal template names" do
      html = render_liquid("{% render '../../etc/passwd' %}")
      expect(html).to include("Liquid error")
      expect(html).to include("Illegal template name")
    end
  end

  describe "variable as template name (Shopify app block compatibility)" do
    it "does not raise SyntaxError for {% render variable %}" do
      expect { render_liquid("{% render block %}") }.not_to raise_error
    end

    it "outputs a placeholder comment when a block-like Hash is passed" do
      html = render_liquid("{% render block %}", { "block" => { "type" => "app" } })
      expect(html).to eq("<!-- render block: type=app -->")
    end

    it "outputs a placeholder for each block in a section.blocks-style loop" do
      html = render_liquid(
        "{%- for block in section_blocks -%}{% render block %}{%- endfor -%}",
        {
          "section_blocks" => [
            { "type" => "app" },
            { "type" => "@app" }
          ]
        }
      )
      expect(html).to eq("<!-- render block: type=app --><!-- render block: type=@app -->")
    end

    it "renders a snippet when the variable resolves to a snippet name string" do
      html = render_liquid("{% render snippet_name %}", { "snippet_name" => "badge" })
      expect(html).to include('<span class="badge">')
    end

    it "outputs a cannot-resolve placeholder when the variable is undefined" do
      html = render_liquid("{% render missing %}")
      expect(html).to eq("<!-- render: cannot resolve template name -->")
    end
  end
end
