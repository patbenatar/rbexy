module Rbexy
  class Configuration
    attr_accessor :component_provider
    attr_accessor :template_paths
    attr_accessor :template_prefixes

    def template_paths
      @template_paths ||= []
    end

    def template_prefixes
      @template_prefixes ||= []
    end
  end
end
