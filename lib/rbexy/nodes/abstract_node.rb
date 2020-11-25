module Rbexy
  module Nodes
    class AbstractNode
      def precompile
        [self]
      end

      def compile
        raise NotImplementedError
      end
    end
  end
end
