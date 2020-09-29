require "active_support/all"
require "action_view/helpers"
require "action_view/context"
require "action_view/buffers"

module Rbexy
  class Runtime
    include ActionView::Context
    include ActionView::Helpers::TagHelper
    include ViewHelper

    DefaultTagBuilder = ActionView::Helpers::TagHelper::TagBuilder

    def self.create_tag_builder(context, provider = Rbexy.configuration.component_provider)
      if provider
        ComponentTagBuilder.new(context, provider)
      else
        ActionView::Helpers::TagHelper::TagBuilder.new(context)
      end
    end

    def initialize(component_provider = nil)
      @rbexy_tag = self.class.create_tag_builder(self, component_provider)
    end

    def evaluate(code)
      instance_eval(code)
    end
  end
end
