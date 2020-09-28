module Rbexy
  class ComponentRuntime
    include Runtime

    attr_reader :tag_builder

    def initialize(component_provider)
      @tag_builder = ComponentTagBuilder.new(self, component_provider)
    end

    def tag
      tag_builder
    end

    class ComponentTagBuilder < ActionView::Helpers::TagHelper::TagBuilder
      attr_reader :component_provider

      def initialize(context, component_provider)
        super(context)
        @component_provider = component_provider
      end

      def method_missing(called, *args, **attrs, &block)
        component_name = called.to_s.gsub("__", "::")
        if component_provider.match?(component_name)
          component_provider.render(component_name, attrs, &block)
        else
          super
        end
      end
    end
  end
end
