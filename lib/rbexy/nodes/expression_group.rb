module Rbexy
  module Nodes
    class ExpressionGroup < AbstractNode
      using Rbexy::Refinements::Array::MapTypeWhenNeighboringType
      using Rbexy::Refinements::Array::InsertBetweenTypes

      attr_accessor :members
      attr_reader :outer_template, :inner_template

      DEBUGGERS = %w[debugger binding.pry]

      OUTPUT_UNSAFE = "@output_buffer.concat(Rbexy::Runtime.expr_out(%s));"
      OUTPUT_SAFE = "@output_buffer.safe_concat(Rbexy::Runtime.expr_out(%s));"
      RAW = "%s"
      DEBUGGER = "#{RAW}\n"
      SUB_EXPR = RAW
      SUB_EXPR_OUT = "Rbexy::Runtime.expr_out(%s)"

      def initialize(members, outer_template: OUTPUT_UNSAFE, inner_template: RAW)
        @members = members
        @outer_template = outer_template
        @inner_template = inner_template
      end

      def precompile
        [if debugger?
          ExpressionGroup.new(precompile_members, outer_template: DEBUGGER, inner_template: RAW)
        else
          ExpressionGroup.new(precompile_members, outer_template: outer_template, inner_template: inner_template)
        end]
      end

      def compile
        outer_template % (inner_template % members.map(&:compile).join)
      end

      private

      def precompile_members
        precompiled = compact(members.map(&:precompile).flatten)

        transformed = precompiled.map do |node|
          case node
          when Raw
            Raw.new(node.content, template: Raw::EXPR_STRING)
          when ComponentElement
            ComponentElement.new(node.name, node.members, node.children, template: ComponentElement::EXPR_STRING)
          when ExpressionGroup
            ExpressionGroup.new(node.members, outer_template: SUB_EXPR, inner_template: node.inner_template)
          else
            node
          end
        end.map_type_when_neighboring_type(ExpressionGroup, Raw) do |node|
          ExpressionGroup.new(node.members, outer_template: SUB_EXPR_OUT, inner_template: node.inner_template)
        end.insert_between_types(ExpressionGroup, Raw) do
          Expression.new("+")
        end.insert_between_types(ComponentElement, Raw) do
          Expression.new("+")
        end
      end

      def debugger?
        members.length == 1 &&
          members.first.is_a?(Expression) &&
          DEBUGGERS.include?(members.first.content.strip)
      end
    end
  end
end
