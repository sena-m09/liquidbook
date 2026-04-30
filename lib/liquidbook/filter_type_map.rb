# frozen_string_literal: true

module Liquidbook
  # Maps Liquid filter names to inferred parameter types.
  # Used by ParameterMerger as a fallback when @param annotations are absent.
  #
  # Type names match ParamParser's normalized types: "text", "number", "checkbox".
  module FilterTypeMap
    FILTER_TYPES = {
      # Numeric filters
      "money" => "number",
      "money_with_currency" => "number",
      "plus" => "number",
      "minus" => "number",
      "times" => "number",
      "divided_by" => "number",
      "modulo" => "number",
      "round" => "number",
      "ceil" => "number",
      "floor" => "number",
      "abs" => "number",
      "at_least" => "number",
      "at_most" => "number",
      # Text filters
      "upcase" => "text",
      "downcase" => "text",
      "capitalize" => "text",
      "strip" => "text",
      "lstrip" => "text",
      "rstrip" => "text",
      "strip_html" => "text",
      "strip_newlines" => "text",
      "newline_to_br" => "text",
      "escape" => "text",
      "escape_once" => "text",
      "url_encode" => "text",
      "url_decode" => "text",
      "truncate" => "text",
      "truncatewords" => "text",
      "append" => "text",
      "prepend" => "text",
      "remove" => "text",
      "remove_first" => "text",
      "replace" => "text",
      "replace_first" => "text",
      "split" => "text",
      "handle" => "text",
      "handleize" => "text",
      "md5" => "text",
      "sha1" => "text",
      "sha256" => "text",
      "base64_encode" => "text",
      "base64_decode" => "text"
    }.freeze

    # Infer a type from a list of filter names.
    # Returns the type if all filters agree, nil if ambiguous or no filters match.
    def self.infer(filters)
      types = filters.filter_map { |f| FILTER_TYPES[f] }.uniq
      types.size == 1 ? types.first : nil
    end
  end
end
