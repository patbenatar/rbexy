module Rbexy
  module Nodes
    class ExpressionGroup < AbstractNode
      attr_reader :statements, :outer_template, :inner_template

      OUTPUT_UNSAFE = "@output_buffer.append=(Rbexy::Runtime.expr_out(%s));"
      OUTPUT_SAFE = "@output_buffer.safe_append=(Rbexy::Runtime.expr_out(%s));"
      SUB_GROUP = "%s"

      def initialize(statements, outer_template: OUTPUT_UNSAFE, inner_template: "%s")
        @statements = statements
        @outer_template = outer_template
        @inner_template = inner_template
      end

      def precompile
        [ExpressionGroup.new(precompile_statements, outer_template: outer_template, inner_template: inner_template)]
      end

      def compile
        outer_template % (inner_template % statements.map(&:compile).join)
      end

      private

      def precompile_statements
        precompiled = compact(statements.map(&:precompile).flatten)

        transformed = precompiled.map do |node|
          # TODO: i think i can use a case statement for class switching like this
          # there's one other spot we do it too...
          if node.is_a?(Raw)
            Raw.new(node.content, template: Raw::EXPR_STRING)
          elsif node.is_a?(ExpressionGroup)
            ExpressionGroup.new(node.statements, outer_template: SUB_GROUP, inner_template: node.inner_template)
          else
            node
          end
        end

        inject(transformed, builder: -> { Expression.new("+") }, between: [Raw, ExpressionGroup])
      end
    end
  end
end
