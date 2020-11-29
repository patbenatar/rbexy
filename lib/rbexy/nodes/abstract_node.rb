module Rbexy
  module Nodes
    class AbstractNode
      def precompile
        [self]
      end

      def compile
        raise NotImplementedError
      end

      private

      def compact(nodes)
        compacted = []
        curr_raw = nil

        nodes.each do |node|
          if node.is_a?(Raw)
            if !curr_raw
              curr_raw ||= Raw.new("")
              compacted << curr_raw
            end
            curr_raw.merge(node)
          else
            curr_raw = nil
            compacted << node
          end
        end

        compacted
      end
    end
  end
end
