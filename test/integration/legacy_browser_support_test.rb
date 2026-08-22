require "test_helper"

class LegacyBrowserSupportTest < ActionDispatch::IntegrationTest
  # None of these tests touch the database, and `fixtures :all` currently blows up on
  # the stale test/fixtures/previsiones.yml. Drop this once that fixture is cleaned up.
  self.fixture_table_names = []

  # User agents for browsers below Rails' `:modern` floor (Safari 17.2, Chrome 120,
  # Firefox 121). Each of these used to be served public/406-unsupported-browser.html.
  LEGACY_USER_AGENTS = {
    "Safari 14.1" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.2 Safari/605.1.15",
    "Chrome 88" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.150 Safari/537.36",
    "Firefox 91" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:91.0) Gecko/20100101 Firefox/91.0",
    "iOS Safari 12" => "Mozilla/5.0 (iPhone; CPU iPhone OS 12_5_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.1.2 Mobile/15E148 Safari/604.1"
  }.freeze

  test "legacy browsers are not blocked" do
    LEGACY_USER_AGENTS.each do |browser, user_agent|
      get team_path, headers: { "HTTP_USER_AGENT" => user_agent }
      assert_response :success, "#{browser} should not be blocked"
    end
  end

  test "import maps are polyfilled ahead of the import map itself" do
    get team_path

    shim = response.body.index("es-module-shims")
    importmap = response.body.index(%(type="importmap"))

    assert shim, "es-module-shims should be loaded"
    assert importmap, "an import map should be rendered"
    assert shim < importmap, "es-module-shims must be loaded before the import map it polyfills"
  end
end
