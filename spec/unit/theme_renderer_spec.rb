# frozen_string_literal: true

require "spec_helper"

RSpec.describe Liquidbook::ThemeRenderer do
  subject(:renderer) { described_class.new }

  describe "#sections" do
    it "lists section names without extension, sorted" do
      expect(renderer.sections).to eq(%w[hero no_schema])
    end
  end

  describe "#snippets" do
    it "lists snippet names without extension" do
      expect(renderer.snippets).to eq(%w[card])
    end
  end

  describe "#render_section" do
    context "with a section that has a schema" do
      it "renders the template using schema defaults" do
        html = renderer.render_section("hero")
        expect(html).to include('<section class="hero">')
        expect(html).to include("Welcome") # schema default for title
      end

      it "renders the show_button default as true" do
        html = renderer.render_section("hero")
        expect(html).to include("<button>Shop Now</button>")
      end

      it "renders default blocks" do
        html = renderer.render_section("hero")
        expect(html).to include("https://placehold.co/800x400")
      end
    end

    context "with a section without schema" do
      it "renders using mock data (product.title from mocks.yml)" do
        html = renderer.render_section("no_schema")
        # mocks.yml overrides product.title to "Override Product"
        expect(html).to include("Override Product")
      end
    end

    # 存在しないテンプレートのエラー
    it "raises Liquidbook::Error for a non-existent section" do
      expect { renderer.render_section("missing") }
        .to raise_error(Liquidbook::Error, /Section not found/)
    end
  end

  describe "#render_snippet" do
    it "renders using @param defaults when no overrides given" do
      html = renderer.render_snippet("card")
      expect(html).to include("My Card")
      expect(html).to include("¥1980")
    end

    it "does not include featured class when featured defaults to false" do
      html = renderer.render_snippet("card")
      expect(html).not_to include("card--featured")
    end

    it "applies overrides to snippet params" do
      html = renderer.render_snippet("card", overrides: { "title" => "Special" })
      expect(html).to include("Special")
    end

    it "raises Liquidbook::Error for a non-existent snippet" do
      expect { renderer.render_snippet("missing") }
        .to raise_error(Liquidbook::Error, /Snippet not found/)
    end
  end

  describe "#snippet_params" do
    it "returns parsed @param definitions for a known snippet" do
      params = renderer.snippet_params("card")
      names = params.map { |p| p["name"] }
      expect(names).to include("title", "price", "featured")
    end

    it "returns empty array for a non-existent snippet" do
      expect(renderer.snippet_params("missing")).to eq([])
    end
  end
end
