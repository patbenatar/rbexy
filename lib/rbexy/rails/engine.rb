require "rbexy/rails"

module Rbexy
  module Rails
    class Engine < ::Rails::Engine
      initializer "rbexy" do |app|
        ActionView::Template.register_template_handler(:rbx, Rbexy::Rails::TemplateHandler)

        ActiveSupport.on_load :action_controller do
          helper Rbexy::ViewHelper
        end

        Rbexy.configure do |config|
          require "rbexy/component_providers/rbexy_provider"
          config.component_provider = Rbexy::ComponentProviders::RbexyProvider.new
        end
      end
    end
  end
end
