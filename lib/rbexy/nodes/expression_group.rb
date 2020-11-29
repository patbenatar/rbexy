module Rbexy
  module Nodes
    class ExpressionGroup < AbstractNode
      attr_reader :statements, :template, :safe

      def initialize(statements, template: "%s", safe: false)
        @statements = statements
        @template = template
        @safe = safe
      end

      def precompile
        [ExpressionGroup.new(precompile_statements, template: template, safe: safe)]
      end

      def compile
        append_meth = safe ? "safe_append" : "append"
        "@output_buffer.#{append_meth}=(#{template % statements.map(&:compile).join});"
      end

      private

      def precompile_statements
        compact(statements.map(&:precompile).flatten).map do |node|
          if node.is_a?(Raw)
            Raw.new(node.content, template: Raw::STRING)
          else
            node
          end
        end
      end
    end
  end
end
