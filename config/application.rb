require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Pretemp
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    config.active_storage.variant_processor = :vips

    # Allow SVG attachments (e.g. forecast maps) to be served inline so they
    # render in <img> tags. By default Rails both (a) forces SVG to be served
    # as a binary attachment and (b) excludes it from the inline allow-list,
    # because SVG can embed scripts. We flip both since only trusted admins
    # upload images. Order matters: it must leave the binary list to be allowed
    # inline.
    config.active_storage.content_types_to_serve_as_binary.delete("image/svg+xml")
    config.active_storage.content_types_allowed_inline += [ "image/svg+xml" ]

    config.i18n.default_locale = :it

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
