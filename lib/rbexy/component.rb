require "action_view"
require "active_support/core_ext/class/attribute"

module Rbexy
  class Component < ActionView::Base
    autoload :BacktraceCleaner, "rbexy/component/backtrace_cleaner"

    class TemplatePath < String
      def to_s
        self
      end
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
    rescue ActionView::Template::Error => error
      error.set_backtrace clean_template_backtrace(error.backtrace)
      raise error
    end

    def content
      content_block ? content_block.call : ""
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

    def clean_template_backtrace(backtrace)
      return backtrace if Rbexy.configuration.debug
      BacktraceCleaner.new(backtrace).call
    end
  end
end
