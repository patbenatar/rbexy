module Rbexy
  module Nodes
    class ComponentProp < AbstractAttr
      def precompile
        [ComponentProp.new(name, precompile_value)]
      end

      def compile
        key = ActiveSupport::Inflector.underscore(name)
        "#{key}: #{value.compile}"
      end

      private

      def precompile_value
        node = value.precompile.first

        case node
        when Raw
          Raw.new(node.content, template: Raw::EXPR_STRING)
        when ExpressionGroup
          ExpressionGroup.new(node.members, outer_template: ExpressionGroup::SUB_EXPR, inner_template: node.inner_template)
        else
          node
        end
      end
    end
  end
end
