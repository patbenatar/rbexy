require "active_support/all"
require "action_view/helpers"
require "action_view/context"
require "action_view/buffers"

module Rbexy
  class HtmlRuntime
    include ActionView::Context
    include ActionView::Helpers::TagHelper

    def evaluate(code)
      instance_eval(code)
    end
  end
end
