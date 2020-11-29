module Rbexy
  module Nodes
    # TODO: will we still need this?
    module Util
      # def self.safe_string(str)
      #   str.gsub('"', '\\"').gsub("'", "\\'")
      # end

      def self.escape_string(str)
        str.gsub('"', '\\"').gsub("'", "\\'")
      end

      def self.safe_tag_name(name)
        name.gsub(".", "__")
      end
    end
  end
end
