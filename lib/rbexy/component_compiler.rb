module Rbexy
  class ComponentCompiler < HtmlCompiler
    attr_reader :component_provider

    def initialize(context, component_provider)
      super(context)
      @component_provider = component_provider
    end

    def tag(name, attrs, &block)
      if component_provider.match?(name)
        component_provider.render(name, attrs, &block)
      else
        super
      end
    end
  end
end
