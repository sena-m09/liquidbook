# frozen_string_literal: true

require "sinatra/base"

module Liquidbook
  module Server
    class App < Sinatra::Base
      RESERVED_QUERY_KEYS = %w[name splat captures q].freeze

      set :views, File.expand_path("views", __dir__)
      set :public_folder, -> { File.join(Liquidbook.root, "assets") }

      before do
        @nav_sections = ThemeRenderer.new(theme_root: Liquidbook.root).sections
        @nav_snippets = ThemeRenderer.new(theme_root: Liquidbook.root).snippets
        @current_path = request.path_info
      end

      helpers do
        def renderer
          @renderer ||= ThemeRenderer.new(theme_root: Liquidbook.root)
        end

        def config
          Liquidbook.config
        end

        def h(text)
          Rack::Utils.escape_html(text.to_s)
        end

        def head_tags
          config.head_tags_html.join("\n")
        end
      end

      # Index page - list all sections and snippets
      get "/" do
        @sections = renderer.sections
        @snippets = renderer.snippets
        erb :index
      end

      # Preview a section
      get "/sections/:name" do
        name = params[:name]
        begin
          overrides = parse_overrides(params)
          @rendered = renderer.render_section(name, overrides: overrides)
          @name = name
          @type = "section"
          @schema = load_schema("sections", name)
          erb :preview
        rescue Liquidbook::Error => e
          status 404
          "Section not found: #{h(name)}"
        end
      end

      # Preview a snippet
      get "/snippets/:name" do
        name = params[:name]
        begin
          @form_params = renderer.snippet_params(name)
          overrides = parse_overrides(params, @form_params)
          @rendered = renderer.render_snippet(name, overrides: overrides)
          @name = name
          @type = "snippet"
          @schema = {}
          @form_params = with_overrides_applied(@form_params, overrides)
          erb :preview
        rescue Liquidbook::Error => e
          status 404
          "Snippet not found: #{h(name)}"
        end
      end

      # Serve imported files from config (CSS/JS from arbitrary paths)
      get "/__imports__/*" do
        serve_path = "/__imports__/#{params["splat"].first}"
        file_path = config.import_files[serve_path]

        if file_path && File.exist?(file_path)
          content_type mime_type(File.extname(file_path)) || "application/octet-stream"
          File.read(file_path)
        else
          status 404
          "Import not found: #{h(serve_path)}"
        end
      end

      # Serve theme assets
      get "/assets/*" do
        file_path = File.join(Liquidbook.root, "assets", params["splat"].first)
        if File.exist?(file_path)
          content_type mime_type(File.extname(file_path)) || "application/octet-stream"
          File.read(file_path)
        else
          status 404
          "Asset not found"
        end
      end

      private

      def load_schema(dir, name)
        path = File.join(Liquidbook.root, dir, "#{name}.liquid")
        return {} unless File.exist?(path)

        SchemaParser.new(File.read(path)).parse
      end

      # Build override hash from query params, coercing types based on @param metadata.
      # Strings (including Japanese / multibyte) pass through as Rack-decoded UTF-8.
      def parse_overrides(params, params_meta = nil)
        type_by_name = build_type_index(params_meta)
        overrides = {}

        params.each do |key, value|
          next if RESERVED_QUERY_KEYS.include?(key)

          overrides[key] = coerce_override(value, type_by_name[key])
        end

        overrides
      end

      def build_type_index(params_meta)
        return {} unless params_meta

        params_meta.each_with_object({}) { |p, h| h[p["name"]] = p["type"] }
      end

      def coerce_override(value, type)
        case type
        when "checkbox" then value.to_s != "false"
        when "number" then coerce_number(value)
        else value
        end
      end

      def coerce_number(value)
        str = value.to_s.strip
        return str if str.empty?

        Integer(str, 10)
      rescue ArgumentError
        begin
          Float(str)
        rescue ArgumentError
          str
        end
      end

      # Return a new params_meta list with each param's "default" replaced by the
      # current override value, so the form re-renders with submitted values.
      # Non-destructive: original hashes are preserved (snippet_params caching-safe).
      def with_overrides_applied(params_meta, overrides)
        params_meta.map do |p|
          name = p["name"]
          overrides.key?(name) ? p.merge("default" => overrides[name]) : p
        end
      end
    end
  end
end
