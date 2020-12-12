module Rbexy
  module Nodes
    module Util
      def self.escape_string(str)
        str.gsub('"', '\\"').gsub("'", "\\'")
      end
    end
  end
end
