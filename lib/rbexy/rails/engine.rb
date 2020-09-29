require "rbexy/rails"

module Rbexy
  module Rails
    class Engine < Rails::Engine
      initializer "rbexy" do |app|
        ActionView::Template.register_template_handler(:rbx, Rbexy::Rails::TemplateHandler)

        ActiveSupport.on_load(:action_view) do
          ActionView::Context.prepend Rbexy::ViewHelper
        end
      end
    end
  end
end
