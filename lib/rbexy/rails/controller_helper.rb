module Rbexy
  module Rails
    module ControllerHelper
      extend ActiveSupport::Concern
      include ComponentContext

      included do
        helper_method :rbexy_context, :create_context, :use_context
      end

      class_methods do
        def inherited(klass)
          super
          Rbexy.configuration.template_paths.each do |path|
            prepend_view_path(ComponentTemplateResolver.new(path))
          end
        end
      end
    end
  end
end
