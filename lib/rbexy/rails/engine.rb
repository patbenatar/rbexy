require "rbexy/rails"

module Rbexy
  module Rails
    class Engine < ::Rails::Engine
      initializer "rbexy" do |app|
        template_handler = ::Rails.version.to_f >= 6.0 ?
          proc { |template, source| Rbexy.compile(source) } :
          proc { |template| Rbexy.compile(template.source) }

        ActionView::Template.register_template_handler(:rbx, template_handler)

        ActiveSupport.on_load :action_controller_base do
          helper Rbexy::ViewContextHelper
          helper_method :rbexy_component_provider

          def rbexy_component_provider; end
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
