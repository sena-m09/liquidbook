# frozen_string_literal: true

require "spec_helper"

RSpec.describe Liquidbook::TemplateAnalyzer do
  describe "#external_variables" do
    it "detects simple variable references" do
      source = "<h1>{{ title }}</h1>"
      result = described_class.new(source).external_variables
      expect(result).to include(
        { name: "title", properties: [{ lookups: [], filters: [] }] }
      )
    end

    it "detects dot-notation property access" do
      source = "<p>{{ product.name }}</p>"
      result = described_class.new(source).external_variables
      product = result.find { |v| v[:name] == "product" }
      expect(product[:properties]).to include({ lookups: ["name"], filters: [] })
    end

    it "detects variables inside if conditions" do
      source = "{% if featured %}<span>yes</span>{% endif %}"
      result = described_class.new(source).external_variables
      expect(result).to include(
        { name: "featured", properties: [{ lookups: [], filters: [] }] }
      )
    end

    it "detects variables in if/elsif/else chains" do
      source = "{% if a %}1{% elsif b %}2{% else %}3{% endif %}"
      result = described_class.new(source).external_variables
      names = result.map { |v| v[:name] }
      expect(names).to include("a", "b")
    end

    it "detects the collection variable in for loops" do
      source = "{% for item in products %}{{ item.name }}{% endfor %}"
      result = described_class.new(source).external_variables
      expect(result).to include(
        { name: "products", properties: [{ lookups: [], filters: [] }] }
      )
    end

    it "excludes loop variables from results" do
      source = "{% for item in products %}{{ item.name }}{% endfor %}"
      result = described_class.new(source).external_variables
      names = result.map { |v| v[:name] }
      expect(names).not_to include("item")
    end

    it "excludes assign local variables" do
      source = '{% assign greeting = "hello" %}{{ greeting }}'
      result = described_class.new(source).external_variables
      names = result.map { |v| v[:name] }
      expect(names).not_to include("greeting")
    end

    it "excludes capture local variables" do
      source = "{% capture msg %}hello{% endcapture %}{{ msg }}"
      result = described_class.new(source).external_variables
      names = result.map { |v| v[:name] }
      expect(names).not_to include("msg")
    end

    it "detects variables used in filter arguments" do
      source = "{{ title | append: suffix }}"
      result = described_class.new(source).external_variables
      names = result.map { |v| v[:name] }
      expect(names).to include("title", "suffix")
    end

    it "returns empty array for templates with no variables" do
      source = "<p>Hello, World!</p>"
      result = described_class.new(source).external_variables
      expect(result).to eq([])
    end

    it "deduplicates identical variable references" do
      source = "{{ title }}{{ title }}"
      result = described_class.new(source).external_variables
      expect(result.count { |v| v[:name] == "title" }).to eq(1)
    end

    it "collects filter names on variables" do
      source = "{{ price | money }}{{ price | plus: 1 }}"
      result = described_class.new(source).external_variables
      price = result.find { |v| v[:name] == "price" }
      expect(price[:properties]).to eq([{ lookups: [], filters: ["money", "plus"] }])
    end

    it "preserves filters when the same variable appears with and without filters" do
      source = "{{ price }}{{ price | money }}"
      result = described_class.new(source).external_variables
      price = result.find { |v| v[:name] == "price" }
      expect(price[:properties]).to eq([{ lookups: [], filters: ["money"] }])
    end

    it "records filter argument variables with empty filters" do
      source = "{{ title | append: suffix }}"
      result = described_class.new(source).external_variables
      suffix = result.find { |v| v[:name] == "suffix" }
      expect(suffix[:properties]).to eq([{ lookups: [], filters: [] }])
    end

    it "collects filters per property separately" do
      source = "{{ product.title | upcase }}{{ product.price | money }}"
      result = described_class.new(source).external_variables
      product = result.find { |v| v[:name] == "product" }
      expect(product[:properties]).to contain_exactly(
        { lookups: ["title"], filters: ["upcase"] },
        { lookups: ["price"], filters: ["money"] }
      )
    end

    context "with fixture templates" do
      it "detects card.liquid snippet variables" do
        source = File.read(File.join(FIXTURE_THEME, "snippets", "card.liquid"))
        result = described_class.new(source).external_variables
        names = result.map { |v| v[:name] }
        expect(names).to include("featured", "title", "price")

        price = result.find { |v| v[:name] == "price" }
        expect(price[:properties].first[:filters]).to include("money")
      end

      it "detects hero.liquid section variables" do
        source = File.read(File.join(FIXTURE_THEME, "sections", "hero.liquid"))
        result = described_class.new(source).external_variables
        section = result.find { |v| v[:name] == "section" }
        lookups = section[:properties].map { |p| p[:lookups] }
        expect(lookups).to include(["settings", "title"])
        expect(lookups).to include(["settings", "show_button"])
        expect(lookups).to include(["blocks"])
      end

      it "detects no_schema.liquid variables" do
        source = File.read(File.join(FIXTURE_THEME, "sections", "no_schema.liquid"))
        result = described_class.new(source).external_variables
        product = result.find { |v| v[:name] == "product" }
        expect(product[:properties]).to include({ lookups: ["title"], filters: [] })
      end
    end
  end

  describe "#section_variable?" do
    it "returns true for section variables" do
      var = { name: "section", properties: [{ lookups: ["settings", "title"], filters: [] }] }
      expect(described_class.new("").section_variable?(var)).to be true
    end

    it "returns false for non-section variables" do
      var = { name: "product", properties: [{ lookups: ["name"], filters: [] }] }
      expect(described_class.new("").section_variable?(var)).to be false
    end
  end
end
