require "rbexy/rails"
require "action_view/dependency_tracker"

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
