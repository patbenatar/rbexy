module Rbexy
  module Nodes
    class AbstractNode
      PrecompileRequired = Class.new(StandardError)

      attr_reader :compile_context

      def precompile
        [self]
      end

      def compile
        raise PrecompileRequired, "#{self.class.name} must be precompiled first"
      end

      def inject_compile_context(context)
        @compile_context = context
        children.each { |c| c.inject_compile_context(context) } if respond_to?(:children)
        members.each { |c| c.inject_compile_context(context) } if respond_to?(:members)
      end

      def transform!
        return unless ast_transformer
        ast_transformer.transform(self, compile_context)
        children.each(&:transform!) if respond_to?(:children)
        members.each(&:transform!) if respond_to?(:members)
      end

      private

      def ast_transformer
        compile_context.ast_transformer
      end

      def compact(nodes)
        compacted = []
        curr_raw = nil

        nodes.each do |node|
          if node.is_a?(Newline) && curr_raw
            curr_raw.merge(Raw.new("\n"))
          elsif node.is_a?(Raw)
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
