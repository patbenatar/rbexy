module Rbexy
  module ViewHelper
    def rbexy_tag
      @rbexy_tag ||= Runtime.create_tag_builder(self)
    end
  end
end
