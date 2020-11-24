module Rbexy
  class Configuration
    attr_accessor :component_provider
    attr_accessor :element_resolver
    attr_accessor :template_paths
    attr_accessor :enable_context
    attr_accessor :debug

    def template_paths
      @template_paths ||= []
    end

    def element_resolver
      @element_resolver ||= ComponentResolver.new
    end
  end
end
