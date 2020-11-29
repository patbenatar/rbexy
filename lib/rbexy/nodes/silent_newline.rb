module Rbexy
  module Nodes
    class SilentNewline < AbstractNode
      def compile
        "\n"
      end
    end
  end
end
