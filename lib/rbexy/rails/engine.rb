require "rbexy/rails"

module Rbexy
  module Rails
    class Engine < ::Rails::Engine
      initializer "rbexy" do |app|
        template_handler = proc { |template, source| Rbexy.compile(source) }

        ActionView::Template.register_template_handler(:rbx, template_handler)

        ActiveSupport.on_load :action_controller_base do
          include ControllerHelper
        end

        if defined?(ViewComponent)
          ViewComponent::Base.include ViewContextHelper
        end

        Rbexy.configure do |config|
          config.template_paths << ::Rails.root.join("app", "components")
          config.enable_context = true
        end
      end
    end
  end
end
