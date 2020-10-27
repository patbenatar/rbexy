module Rbexy
  module ViewContextHelper
    def rbexy_tag
      @rbexy_tag ||= Runtime.create_tag_builder(self)
    end

    def rbexy_context
      @rbexy_context ||= [{}]
    end
  end
end
