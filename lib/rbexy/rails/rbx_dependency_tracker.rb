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
      # Might need to use the comment approach that ActionView/ERB use
      def dependencies
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
