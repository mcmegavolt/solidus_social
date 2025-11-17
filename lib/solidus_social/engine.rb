# frozen_string_literal: true

require 'omniauth-facebook'
require 'omniauth-github'
require 'omniauth-google-oauth2'
require 'omniauth/twitter2'
require 'omniauth/rails_csrf_protection'
require 'deface'
require 'spree/core'
require 'solidus_social/config'
require 'solidus_social/facebook_omniauth_strategy_ext'

module SolidusSocial
  class Engine < Rails::Engine
    include SolidusSupport::EngineExtensions

    isolate_namespace ::Spree

    engine_name 'solidus_social'

    initializer 'solidus_social.ensure_autoload_paths_mutable', before: :set_autoload_paths do |app|
      ActiveSupport::Dependencies.autoload_paths = ActiveSupport::Dependencies.autoload_paths.dup
      ActiveSupport::Dependencies.autoload_once_paths = ActiveSupport::Dependencies.autoload_once_paths.dup

      config.autoload_paths = config.autoload_paths.dup if config.autoload_paths.frozen?
      config.autoload_once_paths = config.autoload_once_paths.dup if config.autoload_once_paths.frozen?
      config.eager_load_paths = config.eager_load_paths.dup if config.eager_load_paths.frozen?

      stack = app.config.middleware if app.respond_to?(:config) && app.config.respond_to?(:middleware)

      if app.respond_to?(:routes_reloader)
        routes_paths = app.routes_reloader.paths
        if routes_paths&.frozen?
          app.routes_reloader.instance_variable_set(:@paths, routes_paths.dup)
        end
      end

      if app.config.respond_to?(:paths)
        routes_config = app.config.paths['config/routes.rb'] rescue nil
        if routes_config && routes_config.instance_variable_defined?(:@paths)
          cfg_paths = routes_config.instance_variable_get(:@paths)
          if cfg_paths&.frozen?
            routes_config.instance_variable_set(:@paths, cfg_paths.dup)
          end
        end
      end
      if stack
        middlewares = stack.instance_variable_get(:@middlewares)
        if middlewares&.frozen?
          stack.instance_variable_set(:@middlewares, middlewares.dup)
        end

        operations = stack.instance_variable_get(:@operations)
        if operations&.frozen?
          stack.instance_variable_set(:@operations, operations.dup)
        end
      end
    end

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    USER_DECORATOR_PATH = root.join(
      "app/decorators/models/solidus_social/spree/user_decorator.rb"
    ).to_s

    initializer 'solidus_social.decorate_spree_user' do |app|
      next unless app.respond_to?(:reloader)

      app.reloader.after_class_unload do
        # Reload and decorate the spree user class immediately after it is
        # unloaded so that it is available to devise when loading routes
        load USER_DECORATOR_PATH
      end
    end
  end
end
