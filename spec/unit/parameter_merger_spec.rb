# frozen_string_literal: true

require "spec_helper"

RSpec.describe Liquidbook::ParameterMerger do
  subject(:merger) do
    described_class.new(variables: variables, param_defs: param_defs)
  end

  let(:variables)  { [] }
  let(:param_defs) { [] }

  describe "#merge" do
    context "when a variable has a matching @param definition" do
      let(:variables) { [{ name: "title", lookups: [] }] }
      let(:param_defs) do
        [{ "name" => "title", "type" => "text", "default" => "My Card", "description" => "Card heading" }]
      end

      it "returns the @param metadata" do
        result = merger.merge
        expect(result).to eq([
          { "name" => "title", "type" => "text", "default" => "My Card", "description" => "Card heading" }
        ])
      end
    end

    context "when a variable has no @param definition" do
      let(:variables) { [{ name: "color", lookups: [] }] }

      it "returns type=unknown with nil default and description" do
        result = merger.merge
        expect(result).to eq([
          { "name" => "color", "type" => "unknown", "default" => nil, "description" => nil }
        ])
      end
    end

    context "when mixing annotated and unannotated variables" do
      let(:variables) do
        [{ name: "title", lookups: [] }, { name: "color", lookups: [] }]
      end
      let(:param_defs) do
        [{ "name" => "title", "type" => "text", "default" => "Hello", "description" => "Heading" }]
      end

      it "returns @param metadata for annotated and unknown for unannotated" do
        result = merger.merge
        title = result.find { |p| p["name"] == "title" }
        color = result.find { |p| p["name"] == "color" }

        expect(title["type"]).to eq("text")
        expect(title["default"]).to eq("Hello")
        expect(color["type"]).to eq("unknown")
        expect(color["default"]).to be_nil
      end
    end

    context "when variables include section references" do
      let(:variables) do
        [
          { name: "title", lookups: [] },
          { name: "section", lookups: ["settings", "title"] },
          { name: "section", lookups: ["blocks"] }
        ]
      end

      it "excludes section variables from the result" do
        names = merger.merge.map { |p| p["name"] }
        expect(names).to eq(["title"])
      end
    end

    context "when the same variable name appears with different lookups" do
      let(:variables) do
        [{ name: "product", lookups: ["title"] }, { name: "product", lookups: ["price"] }]
      end

      it "deduplicates by name" do
        result = merger.merge
        expect(result.count { |p| p["name"] == "product" }).to eq(1)
      end
    end

    context "with an empty variables list" do
      it "returns an empty array" do
        expect(merger.merge).to eq([])
      end
    end

    context "with fixture templates" do
      it "merges card.liquid snippet variables with @param metadata" do
        source = File.read(File.join(FIXTURE_THEME, "snippets", "card.liquid"))
        analyzer = Liquidbook::TemplateAnalyzer.new(source)
        parser = Liquidbook::ParamParser.new(source)

        result = described_class.new(
          variables: analyzer.external_variables,
          param_defs: parser.parse
        ).merge

        names = result.map { |p| p["name"] }
        expect(names).to contain_exactly("title", "price", "featured")

        title = result.find { |p| p["name"] == "title" }
        expect(title["type"]).to eq("text")
        expect(title["default"]).to eq("My Card")
      end

      it "detects no_schema.liquid variables as unknown type" do
        source = File.read(File.join(FIXTURE_THEME, "sections", "no_schema.liquid"))
        analyzer = Liquidbook::TemplateAnalyzer.new(source)

        result = described_class.new(
          variables: analyzer.external_variables,
          param_defs: []
        ).merge

        product = result.find { |p| p["name"] == "product" }
        expect(product["type"]).to eq("unknown")
        expect(product["default"]).to be_nil
      end
    end
  end
end
