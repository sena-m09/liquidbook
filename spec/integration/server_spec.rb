# frozen_string_literal: true

require "spec_helper"

RSpec.describe Liquidbook::Server::App, type: :integration do
  before(:all) do
    Liquidbook::Server::App.set :environment, :test
  end

  def app
    Liquidbook::Server::App
  end

  # GET / — セクション/スニペット一覧
  describe "GET /" do
    it "returns 200 and lists sections and snippets" do
      get "/"
      expect(last_response.status).to eq(200)
      expect(last_response.body).to include("hero")
      expect(last_response.body).to include("card")
    end
  end

  # GET /sections/:name — セクションプレビュー
  describe "GET /sections/:name" do
    context "with an existing section" do
      it "returns 200 with rendered content" do
        get "/sections/hero"
        expect(last_response.status).to eq(200)
        expect(last_response.body).to include("Welcome")
      end
    end

    context "with a missing section" do
      it "returns 404" do
        get "/sections/does_not_exist"
        expect(last_response.status).to eq(404)
      end
    end
  end

  # GET /snippets/:name — スニペットプレビュー
  describe "GET /snippets/:name" do
    context "with an existing snippet" do
      it "returns 200 with rendered snippet using @param defaults" do
        get "/snippets/card"
        expect(last_response.status).to eq(200)
        expect(last_response.body).to include("My Card")
        expect(last_response.body).to include("¥1980")
      end
    end

    context "with a missing snippet" do
      it "returns 404" do
        get "/snippets/does_not_exist"
        expect(last_response.status).to eq(404)
      end
    end

    context "with query parameter overrides" do
      it "applies a string override to the rendered output" do
        get "/snippets/card", title: "Query Title"
        expect(last_response.status).to eq(200)
        expect(last_response.body).to include("Query Title")
      end

      it "preserves multibyte (Japanese) string overrides" do
        get "/snippets/card", title: "テスト商品"
        expect(last_response.status).to eq(200)
        expect(last_response.body).to include("テスト商品")
      end

      it "coerces number overrides to numeric values for filters" do
        get "/snippets/card", price: "2980"
        expect(last_response.status).to eq(200)
        expect(last_response.body).to include("¥2980")
      end

      it "coerces checkbox value=true to true" do
        get "/snippets/card", featured: "true"
        expect(last_response.status).to eq(200)
        expect(last_response.body).to include("card--featured")
      end

      it "coerces checkbox value=false to false" do
        get "/snippets/card", featured: "false"
        expect(last_response.status).to eq(200)
        expect(last_response.body).not_to include("card--featured")
      end

      it "preserves @param checkbox defaults when the key is absent" do
        # The radio pair always sends a value when the form is submitted;
        # absence means a non-form-submission (e.g. direct URL with only title).
        get "/snippets/card", title: "Other"
        expect(last_response.status).to eq(200)
        expect(last_response.body).not_to include("card--featured")
      end

      it "ignores the sidebar search q parameter when building overrides" do
        get "/snippets/card", q: "card"
        expect(last_response.status).to eq(200)
        expect(last_response.body).to include("My Card")
      end
    end
  end

  # GET /__imports__/* — config で宣言されたファイルの配信
  describe "GET /__imports__/*" do
    # Config のロジックから実際の serve path を取得（再実装を避ける）
    let(:serve_path) do
      Liquidbook::Config.new.import_files.keys.first
    end

    it "serves the file when the import path exists" do
      get serve_path
      expect(last_response.status).to eq(200)
      expect(last_response.body).to include("fixture")
    end

    it "returns 404 for an unknown import path" do
      get "/__imports__/nonexistent_file.css"
      expect(last_response.status).to eq(404)
    end
  end
end
