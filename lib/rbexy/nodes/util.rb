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

      # TODO: namespaced components
      def self.safe_tag_name(name)
        name.gsub(".", "__")
      end

      def self.inject(collection, builder:, between:)
        collection.map.with_index do |curr, i|
          prev_i = i - 1

          if prev_i >= 0 && one_of_each_type?([collection[prev_i], curr], between)
            [builder.call, curr]
          else
            [curr]
          end
        end.flatten
      end

      def self.one_of_each_type?(items_pair, types_pair)
        items_pair[0].is_a?(types_pair[0]) && items_pair[1].is_a?(types_pair[1]) ||
          items_pair[0].is_a?(types_pair[1]) && items_pair[1].is_a?(types_pair[0])
      end
    end
  end
end
