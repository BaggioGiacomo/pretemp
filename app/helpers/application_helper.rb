module ApplicationHelper
  # Drop-in replacement for `javascript_importmap_tags` that keeps the app running on
  # browsers without native import map support (before Safari 16.4, Chrome 89 and
  # Firefox 108), which would otherwise execute none of our JavaScript at all.
  #
  # es-module-shims feature-detects import maps and stays inert when the browser
  # already handles them, so it costs modern visitors nothing but the async request.
  # It has to be emitted *before* the import map it polyfills.
  def javascript_importmap_tags_with_shim(entry_point = "application")
    safe_join [
      javascript_include_tag("es-module-shims", async: true, "data-turbo-track": "reload"),
      javascript_importmap_tags(entry_point)
    ], "\n"
  end
end
