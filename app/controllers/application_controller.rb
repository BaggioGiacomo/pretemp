class ApplicationController < ActionController::Base
  include Pagy::Method

  # No `allow_browser` restriction on purpose: older browsers are supported rather
  # than served public/406-unsupported-browser.html. Import maps, the one hard
  # requirement they miss, are polyfilled in the layouts.

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes
end
