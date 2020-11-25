module Rbexy
  module Nodes
    class Root < AbstractNode
      attr_reader :children

      def initialize(children)
        @children = children
      end

      def precompile
        Root.new(children.map(&:precompile).flatten)
      end

      def compile
        # TODO: figure out rbexy_prep_output() for html safe arrays
        "#{children.map(&:compile).join};@output_buffer.to_s"
      end
    end
  end
end
