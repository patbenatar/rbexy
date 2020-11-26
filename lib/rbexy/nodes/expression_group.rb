module Rbexy
  module Nodes
    class ExpressionGroup < AbstractNode
      attr_reader :statements, :template, :safe

      def initialize(statements, template: "%s", safe: false)
        @statements = statements
        @template = template
        @safe = safe
      end

      def compile
        append_meth = safe ? "safe_append" : "append"
        "@output_buffer.#{append_meth}=(#{template % statements.map(&:compile).join});"
      end
    end
  end
end
