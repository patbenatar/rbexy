require "action_view"
require "active_support/core_ext/class/attribute"

module Rbexy
  class Component < ActionView::Base
    class TemplatePath < String
      def to_s
        self
      end
    end

    class_attribute :component_file_location

    def self.inherited(klass)
      klass.component_file_location = caller_locations(1, 10).reject { |l| l.label == "inherited" }[0].absolute_path
    end

    def self.component_name
      name.underscore
    end

    def component_name
      self.class.component_name
    end

    def initialize(view_context, **props)
      super(
        view_context.lookup_context,
        view_context.assigns,
        view_context.controller
      )

      @view_context = view_context

      setup(**props)
    end

    # Override in your subclass to handle props, setup your component, etc.
    # You can also implement `initialize` but you just need to remember to
    # call super(view_context).
    def setup(**props); end

    def render(&block)
      @content_block = block_given? ? block : nil
      call
    end

    def call
      path = TemplatePath.new(component_name)
      template = view_context.lookup_context.find(path)
      template.render(self, {})
    end

    def content
      content_block ? view_context.capture(self, &content_block) : ""
    end

    def create_context(name, value)
      rbexy_context.last[name] = value
    end

    def use_context(name)
      index = rbexy_context.rindex { |c| c.has_key?(name) }
      index ?
        rbexy_context[index][name] :
        raise(ContextNotFound, "no parent context `#{name}`")
    end

    def compiled_method_container
      Rbexy::Component
    end

    private

    attr_reader :view_context, :content_block

    def method_missing(meth, *args, &block)
      if view_context.respond_to?(meth)
        view_context.send(meth, *args, &block)
      else
        super
      end
    end
  end
end
