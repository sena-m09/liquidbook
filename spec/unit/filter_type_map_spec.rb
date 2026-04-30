# frozen_string_literal: true

require "spec_helper"

RSpec.describe Liquidbook::FilterTypeMap do
  describe ".infer" do
    it "returns number for numeric filters" do
      expect(described_class.infer(["money"])).to eq("number")
      expect(described_class.infer(["plus", "minus"])).to eq("number")
      expect(described_class.infer(["round"])).to eq("number")
    end

    it "returns text for string filters" do
      expect(described_class.infer(["upcase"])).to eq("text")
      expect(described_class.infer(["append", "truncate"])).to eq("text")
      expect(described_class.infer(["handle"])).to eq("text")
    end

    it "returns nil when filters suggest conflicting types" do
      expect(described_class.infer(["money", "upcase"])).to be_nil
    end

    it "returns nil for empty filters" do
      expect(described_class.infer([])).to be_nil
    end

    it "returns nil for unknown filters" do
      expect(described_class.infer(["some_custom_filter"])).to be_nil
    end

    it "ignores unknown filters when known filters agree" do
      expect(described_class.infer(["money", "some_custom_filter"])).to eq("number")
    end
  end
end
