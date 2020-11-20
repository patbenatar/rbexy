require "rbexy/rails"

module Rbexy
  module Rails
    class Engine < ::Rails::Engine
      initializer "rbexy" do |app|
        template_handler = proc { |template, source| Rbexy.compile(source) }

        ActionView::Template.register_template_handler(:rbx, template_handler)

        ActiveSupport.on_load :action_controller_base do
          helper Rbexy::ViewContextHelper
          helper_method :rbexy_component_provider
          include ControllerHelper
        end

        if defined?(ViewComponent)
          ViewComponent::Base.include Rbexy::ViewContextHelper
        end

        Rbexy.configure do |config|
          require "rbexy/component_providers/rbexy_provider"
          config.component_provider = Rbexy::ComponentProviders::RbexyProvider.new
          config.template_paths << ::Rails.root.join("app", "components")
          config.enable_context = true
        end
      end
    end
  end
end
