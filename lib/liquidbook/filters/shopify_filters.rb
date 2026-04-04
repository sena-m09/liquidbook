# frozen_string_literal: true

module Liquidbook
  module Filters
    # Common Shopify Liquid filters for local preview
    module ShopifyFilters
      # Asset URL filters
      def asset_url(input)
        "/assets/#{input}"
      end

      def asset_img_url(input, size = nil)
        return input unless input.is_a?(String)

        "/assets/#{input}"
      end

      def image_url(input, width: nil, height: nil, **_opts)
        return "" unless input

        src = input.is_a?(Hash) ? input["src"] : input.to_s
        params = []
        params << "width=#{width}" if width
        params << "height=#{height}" if height
        params.empty? ? src : "#{src}?#{params.join("&")}"
      end

      def img_tag(input, alt: "")
        %(<img src="#{input}" alt="#{alt}" loading="lazy">)
      end

      # Money filters
      def money(input)
        return "" unless input

        "¥#{format("%d", input.to_i)}"
      end

      def money_with_currency(input)
        "#{money(input)} JPY"
      end

      # String filters (Shopify extensions)
      def handle(input)
        return "" unless input

        input.to_s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-|-$/, "")
      end

      def handleize(input)
        handle(input)
      end

      def pluralize(input, singular, plural)
        input.to_i == 1 ? singular : plural
      end

      # URL filters
      def link_to(input, url, title = "")
        title_attr = title.to_s.empty? ? "" : %( title="#{title}")
        %(<a href="#{url}"#{title_attr}>#{input}</a>)
      end

      def within(url, collection_url)
        "#{collection_url}#{url}"
      end

      def stylesheet_tag(url)
        %(<link rel="stylesheet" href="#{url}" type="text/css">)
      end

      def script_tag(url)
        %(<script src="#{url}"></script>)
      end

      # Collection / pagination helpers
      def paginate(input, page_size)
        input
      end

      def default_pagination(_input)
        ""
      end

      # JSON / data
      def json(input)
        require "json"
        input.to_json
      end

      # Translation stub
      def t(input)
        input.to_s
      end

      # Placeholder image
      def placeholder_svg_tag(type)
        %(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect width="100" height="100" fill="#eee"/><text x="50" y="50" text-anchor="middle" dy=".3em" fill="#999">#{type}</text></svg>)
      end

      # Color filters
      def color_to_rgb(input)
        input.to_s
      end

      def color_modify(input, _attr, _value)
        input.to_s
      end

      def color_to_hex(input)
        input.to_s
      end

      def color_brightness(input)
        128
      end

      # Font filters
      def font_modify(input, _attr, _value)
        input
      end

      def font_url(input)
        ""
      end

      def font_face(input)
        ""
      end

      # Media filters
      def external_video_url(input, **_opts)
        input.to_s
      end

      def media_tag(input, **_opts)
        %(<div class="media-placeholder">#{input}</div>)
      end

      # Metafield
      def metafield_tag(input)
        input.to_s
      end
    end
  end
end
