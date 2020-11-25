module Rbexy
  module Nodes
    class ExpressionGroup < AbstractNode
      attr_reader :statements

      def initialize(statements)
        @statements = statements
      end

      def compile
        statements.map(&:compile).join
      end
    end
  end
end
