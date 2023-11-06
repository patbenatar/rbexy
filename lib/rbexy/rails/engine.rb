require "rbexy/rails"
require "action_view/dependency_tracker"

# Rails 7.1 implements development-mode template caching in a way that only works with view paths registered as
# strings with `prepend_view_path`. Since we register our view paths as `ComponentTemplateResolver` instances (which
# are subclasses of Rails `FileSytemResolver`), we have to monkey-patch Rails to make it think our custom resolvers
# are file system resolvers and thus should be supported by its caching mechanism.
if ActionView.version >= Gem::Version.new("7.1")
  require "action_view/path_registry"
  module ActionView
    module PathRegistry
      class << self
        alias_method :_original_cast_file_system_resolvers, :cast_file_system_resolvers
      end

      def self.cast_file_system_resolvers(paths)
        Array(paths).each do |path|
          next unless path.is_a?(Rbexy::Rails::ComponentTemplateResolver)
          @file_system_resolvers[path] ||= path
          file_system_resolver_hooks.each(&:call)
        end

        _original_cast_file_system_resolvers(paths)
      end
    end
  end
end

module Rbexy
  module Rails
    class Engine < ::Rails::Engine
      initializer "rbexy" do |app|
        template_handler = proc { |template, source| Rbexy.compile(Rbexy::Template.new(source, template.identifier)) }

        ActionView::Template.register_template_handler(:rbx, template_handler)
        ActionView::DependencyTracker.register_tracker(:rbx, RbxDependencyTracker)

        ActiveSupport.on_load :action_controller_base do
          include ControllerHelper
        end

        Rbexy.configure do |config|
          config.template_paths << ::Rails.root.join("app", "components")
          config.enable_context = true
        end
      end
    end
  end
end
