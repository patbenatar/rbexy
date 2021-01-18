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

      def dependencies
        rails_render_helper_dependencies + rbexy_dependencies
      end

      private

      attr_reader :name, :template, :view_paths

      def rails_render_helper_dependencies
        ActionView::DependencyTracker::ERBTracker.call(name, template, view_paths)
      end

      def rbexy_dependencies
        Lexer.new(template, Rbexy.configuration.element_resolver).tokenize
          .select { |t| t[0] == :TAG_DETAILS && t[1][:type] == :component }
          .map { |t| t[1][:component_class] }
          .uniq
          .map(&:template_path)
      end
    end
  end
end
