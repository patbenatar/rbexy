module Rbexy
  module Refinements
    module Array
      module InsertBetweenTypes
        refine ::Array do
          def insert_between_types(type1, type2, &block)
            map.with_index do |curr, i|
              prev_i = i - 1

              if prev_i >= 0 && InsertBetweenTypes.one_of_each_type?([self[prev_i], curr], [type1, type2])
                [block.call, curr]
              else
                [curr]
              end
            end.flatten
          end
        end

        def self.one_of_each_type?(items_pair, types_pair)
          items_pair[0].is_a?(types_pair[0]) && items_pair[1].is_a?(types_pair[1]) ||
            items_pair[0].is_a?(types_pair[1]) && items_pair[1].is_a?(types_pair[0])
        end
      end
    end
  end
end
