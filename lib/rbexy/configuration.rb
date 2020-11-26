module Rbexy
  class Configuration
    attr_accessor :element_resolver
    attr_accessor :template_paths
    attr_accessor :enable_context
    attr_accessor :debug
    attr_accessor :component_rendering_templates

    def template_paths
      @template_paths ||= []
    end

    def element_resolver
      @element_resolver ||= ComponentResolver.new
    end

    # TODO: write docs showing how to customize this for ViewComponent
    # or provide a :view_component option?
    def component_rendering_templates
      @component_rendering_templates ||= {
        children: "{capture{%{children}}}",
        component: "::%{component_class}.new(%{view_context},%{kwargs}).render%{children_block}"
      }
    end
  end
end
