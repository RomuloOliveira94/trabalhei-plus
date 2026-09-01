require "test_helper"

# Phase 6: PWA static assets in public/ — manifest, generated icons and the
# offline page. These are plain files served by the app, so integration tests
# assert content type and body (the Selenium driver cannot read headers).
class PwaTest < ActionDispatch::IntegrationTest
  test "manifest.webmanifest is served as valid JSON with the new branding" do
    get "/manifest.webmanifest"

    assert_response :success
    assert_equal "application/manifest+json", response.media_type
    manifest = JSON.parse(response.body)
    assert_equal "Trabalhei +", manifest["name"]
    assert_equal "Trabalhei +", manifest["short_name"]
    assert_equal "/overtimes", manifest["start_url"]
    assert_equal "#dc2626", manifest["theme_color"]
    assert_equal "#ffffff", manifest["background_color"]
    assert_equal 2, manifest["icons"].length
  end

  test "PWA icons are served as PNG bytes" do
    get "/icon-192.png"
    assert_response :success
    assert_equal "image/png", response.media_type
    assert response.body.start_with?("\x89PNG".b)

    get "/icon-512.png"
    assert_response :success
    assert_equal "image/png", response.media_type
    assert response.body.start_with?("\x89PNG".b)
  end

  test "favicon.svg and legacy favicon.ico are served" do
    get "/icon.svg"
    assert_response :success
    assert_equal "image/svg+xml", response.media_type

    get "/favicon.ico"
    assert_response :success
    assert_equal "image/vnd.microsoft.icon", response.media_type
  end

  test "offline page is served with the pt-BR message" do
    get "/offline"

    assert_response :success
    body = response.body.dup.force_encoding(Encoding::UTF_8)
    assert_includes body, "Você está offline"
    assert_includes body, "Reconecte para continuar."
  end
end
