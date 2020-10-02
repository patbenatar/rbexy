require "action_view"

module Rbexy
  class Component < ActionView::Base
    class_attribute :component_file_location

    def self.inherited(klass)
      klass.component_file_location = caller_locations(1, 10).reject { |l| l.label == "inherited" }[0].absolute_path
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
      @content = nil
      @content_block = block_given? ? block : nil
      call
    end

    def call
      source = File.read(template_path)
      handler = ActionView::Template.handler_for_extension(File.extname(template_path).gsub(".", ""))
      locals = []
      template = ActionView::Template.new(source, component_name, handler, locals: locals)
      template.render(self, locals)
    end

    def content
      @content ||= content_block ? view_context.capture(self, &content_block) : ""
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

    private

    attr_reader :view_context, :content_block

    def template_path
      # Look for template as sibling to component class, with the same filename
      # but a template extension instead of `.rb`
      template_root_path = self.class.component_file_location.chomp(File.extname(self.class.component_file_location))

      extensions = ActionView::Template.template_handler_extensions.join(",")
      template_files = Dir["#{template_root_path}.*{#{extensions}}"]

      if template_files.length > 1
        raise AmbiguousTemplate, "found #{template_files.length} templates for #{self.class.name}"
      elsif template_files.length == 0
        raise TemplateNotFound, "couldn't find template for #{self.class.name}"
      else
        template_files.first
      end
    end

    def component_name
      self.class.name.underscore
    end

    def method_missing(meth, *args, &block)
      if view_context.respond_to?(meth)
        view_context.send(meth, *args, &block)
      else
        super
      end
    end
  end
end
