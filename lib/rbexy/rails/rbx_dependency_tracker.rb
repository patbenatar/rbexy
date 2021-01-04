module Rbexy
  module Rails
    class RbxDependencyTracker
      def self.supports_view_paths?
        true
      end

      def self.call(name, template, view_paths = nil)
        new(name, template, view_paths).dependencies
      end

      def initialize(name, template, view_paths = nil)
        @name, @template, @view_paths = name, template, view_paths
      end

      # TODO: how to handle #call components?
      # See comment in ComponentTemplateResolver
      def dependencies
        # TODO: concat the results from the Erb handler, as rbx templates can also make `view_context.render` calls
        # (check if those regexes would match with the `view_context.` prefix though...)
        # Related: consider renaming `Rbexy::Component#render` to something else (maybe `#render_in` for future
        # compat with Rails 6.1+ object rendering?) to avoid the naming collision.
        Lexer.new(template, Rbexy.configuration.element_resolver).tokenize
          .select { |t| t[0] == :TAG_DETAILS && t[1][:type] == :component }
          .map { |t| t[1][:component_class] }
          .reject(&:call_component?)
          .uniq
          .map(&:template_path)
      end

      private

      attr_reader :name, :template

      def source
        template.source
      end
    end
  end
end
