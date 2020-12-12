module Rbexy
  module Refinements
    module Array
      module MapTypeWhenNeighboringType
        refine ::Array do
          def map_type_when_neighboring_type(map_type, neighboring_type, &block)
            map.with_index do |curr, i|
              prev_i = i - 1
              next_i = i + 1

              if !curr.is_a?(map_type)
                curr
              elsif prev_i >= 0 && self[prev_i].is_a?(neighboring_type)
                block.call(curr)
              elsif next_i < length && self[next_i].is_a?(neighboring_type)
                block.call(curr)
              else
                curr
              end
            end
          end
        end
      end
    end
  end
end
