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
        if component_provider.match?(name)
          component_provider.render(name, attrs, &block)
        else
          super
        end
      end
    end
  end
end
