require "application_system_test_case"

# Phase 6: PWA support — the layout wires up the manifest, icons, theme color
# and service worker registration. Static-file serving (manifest JSON, PNG
# bytes) is covered by the integration test (test/integration/pwa_test.rb)
# because the Selenium driver does not expose response headers.
class PwaTest < ApplicationSystemTestCase
  test "layout references the manifest, icons and theme color" do
    visit root_path

    assert_selector 'link[rel="manifest"][href="/manifest.webmanifest"]', visible: false
    assert_selector 'link[rel="icon"][href="/icon.svg"]', visible: false
    assert_selector 'link[rel="alternate icon"][href="/favicon.ico"]', visible: false
    assert_selector 'link[rel="apple-touch-icon"][href="/icon.svg"]', visible: false
    assert_selector 'meta[name="theme-color"][content="#dc2626"]', visible: false
  end

  test "layout registers the service worker" do
    visit root_path

    assert page.html.include?('navigator.serviceWorker.register("/sw.js")')
  end

  test "offline page renders the pt-BR message" do
    visit "/offline"

    assert_text "Você está offline"
    assert_text "Reconecte para continuar."
  end
end
