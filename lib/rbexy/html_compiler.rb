require "active_support/all"
require "action_view/helpers"
require "action_view/context"
require "action_view/buffers"

module Rbexy
  class HtmlCompiler
    include ActionView::Context
    include ActionView::Helpers::TagHelper

    attr_reader :context, :tag_helper

    def initialize(context)
      @context = context
    end

    def eval(code)
      context.instance_eval(code)
    end

    def tag(name, attrs, &block)
      children = block.call
      if children.length > 0
        content_tag(name, **attrs) { children.html_safe }
      else
        super(name, **attrs)
      end
    end
  end
end
