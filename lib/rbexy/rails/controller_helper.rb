require "active_support/concern"

module Rbexy
  module Rails
    module ControllerHelper
      extend ActiveSupport::Concern

      def rbexy_component_provider; end

      class_methods do
        def inherited(klass)
          super
          Rbexy.configuration.template_paths.each do |path|
            prepend_view_path(Rbexy::Rails::ComponentTemplateResolver.new(path))
          end
        end
      end
    end
  end
end
