module Rbexy
  module Rails
    class RbxDependencyTracker < ActionView::DependencyTracker::ERBTracker
      def dependencies
        super + rbexy_component_dependencies
      end

      private

      def render_dependencies
        dependencies = []

        # Scan for render calls inside Rbexy {expr} expressions
        render_calls = source.scan(/\{(?:(?:(?!\{).)*?\brender\b((?:(?!\}).)*?))\}/m).flatten

        # Also scan for ERB-style render calls (in case of mixed syntax)
        render_calls += source.scan(/<%(?:(?:(?!<%).)*?\brender\b((?:(?!%>).)*?))%>/m).flatten

        render_calls.each do |arguments|
          add_dependencies(dependencies, arguments, LAYOUT_DEPENDENCY)
          add_dependencies(dependencies, arguments, RENDER_ARGUMENTS)
        end

        dependencies
      end

      def rbexy_component_dependencies
        Lexer.new(template, Rbexy.configuration.element_resolver).tokenize
          .select { |t| t[0] == :TAG_DETAILS && t[1][:type] == :component }
          .map { |t| t[1][:component_class] }
          .uniq
          .map(&:template_path)
      end
    end
  end
end
