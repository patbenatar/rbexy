module Rbexy
  module Nodes
    class ComponentProp < XMLAttr
      def compile
        "\"#{name}\": #{value.compile}"
      end
    end
  end
end
