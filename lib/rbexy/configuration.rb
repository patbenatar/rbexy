module Rbexy
  class Configuration
    attr_accessor :component_provider
    attr_accessor :template_paths
    attr_accessor :enable_context

    def template_paths
      @template_paths ||= []
    end
  end
end
