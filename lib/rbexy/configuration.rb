module Rbexy
  class Configuration
    attr_accessor :component_provider
    attr_accessor :template_paths

    def template_paths
      @template_paths ||= []
    end
  end
end
