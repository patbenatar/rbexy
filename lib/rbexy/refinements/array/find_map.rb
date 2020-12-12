module Rbexy
  module Refinements
    module Array
      module FindMap
        refine ::Array do
          def find_map
            lazy.map { |i| yield(i) }.reject { |v| !v }.first
          end
        end
      end
    end
  end
end
