require "rbexy/rails"

module Rbexy
  module Rails
    class Engine < ::Rails::Engine
      initializer "rbexy" do |app|
        ActionView::Template.register_template_handler(:rbx, Rbexy::Rails::TemplateHandler)

        ActiveSupport.on_load :action_controller_base do
          helper Rbexy::ViewContextHelper
        end

        if defined?(ViewComponent)
          ViewComponent::Base.include Rbexy::ViewContextHelper
        end

        Rbexy.configure do |config|
          require "rbexy/component_providers/rbexy_provider"
          config.component_provider = Rbexy::ComponentProviders::RbexyProvider.new
          config.template_paths << ::Rails.root.join("app", "components")
        end
      end
    end
  end
end
