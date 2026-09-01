# Phase 6: the PWA manifest is a static file in public/ served by Rack, so
# the webmanifest extension must be registered with Rack's mime table (Rails'
# Mime::Type only covers the app's own renderers). Without this the file is
# served as text/plain and browsers refuse to install the app.
Rack::Mime::MIME_TYPES[".webmanifest"] = "application/manifest+json"
