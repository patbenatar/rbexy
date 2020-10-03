require "action_view"

module Rbexy
  class Component < ActionView::Base
    class LookupContext < ActionView::LookupContext
      def self.details_hash(context)
        context.registered_details.each_with_object({}) do |key, details_hash|
          value = key == :locale ? [context.locale] : context.send(key)
          details_hash[key] = value
        end
      end

      def args_for_lookup(name, prefixes, partial, keys, details_options)
        super(name, prefixes, false, keys, details_options)
      end
    end

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
      renderer = view_context.view_renderer

      old_lookup_context = renderer.lookup_context

      paths = old_lookup_context.view_paths.dup.unshift(
        ActionView::OptimizedFileSystemResolver.new(::Rails.root.join("app", "components"))
      )

      details = LookupContext.details_hash(old_lookup_context)
      # TODO: this should go in app-code, not Rbexy...
      prefixes = %w(atoms molecules organisms)
      new_lookup_context = LookupContext.new(paths, details, prefixes)

      renderer.lookup_context = new_lookup_context
      renderer.render(self, partial: component_name, &nil)
    ensure
      renderer.lookup_context = old_lookup_context
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
