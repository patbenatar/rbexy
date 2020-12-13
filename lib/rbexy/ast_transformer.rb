module Rbexy
  class ASTTransformer
    attr_reader :registry

    def initialize
      clear!
    end

    def register(*node_classes, &block)
      node_classes.each { |k| (registry[k] ||= []) << block }
    end

    def transform(node, context)
      registry[node.class]&.each { |t| t.call(node, context) }
    end

    def clear!
      @registry = {}
    end
  end
end
