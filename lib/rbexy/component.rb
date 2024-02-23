require "active_support/core_ext/class/attribute"

module Rbexy
  class Component < ActionView::Base
    autoload :BacktraceCleaner, "rbexy/component/backtrace_cleaner"

    class TemplatePath < String
      def to_s
        self
      end

      def split(*args)
        super.map { |s| TemplatePath.new(s) }
      end

      def gsub(*args)
        super.tap { |s| break TemplatePath.new(s) }
      end

      def from(*args)
        super.tap { |s| break TemplatePath.new(s) }
      end
    end

    class_attribute :component_file_location

    def self.inherited(klass)
      klass.component_file_location = caller_locations(1, 10).reject { |l| l.label == "inherited" }[0].absolute_path
    end

    def self.template_path
      TemplatePath.new(component_name)
    end

    def self.call_component?
      method_defined?(:call)
    end

    def self.component_name
      name.underscore
    end

    def initialize(view_context, **props)
      super(
        view_context.lookup_context,
        view_context.assigns,
        view_context.controller
      )

      @view_context = view_context

      after_initialize(**props)
    end

    # Override in your subclass to handle props, setup your component, etc.
    # You can also implement `initialize` but you just need to remember to
    # call super(view_context).
    def setup(**props); end

    def render_in(_context = view_context, &block)
      @content_block = block_given? ? block : nil
      self.class.call_component? ? call : _render
    end

    # Explicitly delegate `render` to the view_context rather than super,
    # so `render partial: "..."` calls run in the expected context.
    def render(*args)
      view_context.render(*args)
    end

    def content
      content_block ? content_block.call : ""
    end

    def compiled_method_container
      Rbexy::Component
    end

    private

    attr_reader :view_context, :content_block

    def _render
      path = self.class.template_path
      template = view_context.lookup_context.find(path)
      template.render(self, {})
    rescue ActionView::Template::Error => error
      error.set_backtrace clean_template_backtrace(error.backtrace)
      error.cause.set_backtrace clean_template_backtrace(error.cause.backtrace)
      raise error
    end

    def method_missing(meth, *args, **kwargs, &block)
      view_context.send(meth, *args, **kwargs, &block)
    end

    def respond_to_missing?(method_name, include_all)
      view_context.respond_to?(method_name, include_all)
    end

    def clean_template_backtrace(backtrace)
      return backtrace if Rbexy.configuration.debug
      BacktraceCleaner.new(backtrace).call
    end

    def after_initialize(**props)
      setup(**props)
    end
  end
end
