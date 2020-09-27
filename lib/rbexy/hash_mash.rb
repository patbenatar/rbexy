module Rbexy
  class HashMash < Hash
    def initialize(hash)
      replace(hash)
    end

    def method_missing(meth, *args, &block)
      if has_key?(meth)
        self[meth]
      else
        super
      end
    end
  end
end
