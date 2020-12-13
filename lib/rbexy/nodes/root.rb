module Rbexy
  module Nodes
    class Root < AbstractNode
      attr_accessor :children

      def initialize(children)
        @children = children
      end

      def precompile
        Root.new(compact(children.map(&:precompile).flatten))
      end

      def compile
        "#{children.map(&:compile).join}@output_buffer.to_s"
      end
    end
  end
end
