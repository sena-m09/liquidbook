# frozen_string_literal: true

require "rack/test"
require "json"
require "liquidbook"

FIXTURE_THEME = File.expand_path("fixtures/theme", __dir__)

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.order = :random
  config.warnings = true

  # テスト間でモジュールレベルの状態が汚染されないようにリセットする
  config.before(:each) do
    Liquidbook.reset!
    Liquidbook.root = FIXTURE_THEME
  end

  # Rack::Test はインテグレーションテストのみで使用
  config.include Rack::Test::Methods, type: :integration
end
