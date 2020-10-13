require "active_support/all"
require "action_view/helpers"
require "action_view/context"
require "action_view/buffers"

module Rbexy
  class Runtime
    include ActionView::Context
    include ActionView::Helpers::TagHelper
    include ViewContextHelper

    DefaultTagBuilder = ActionView::Helpers::TagHelper::TagBuilder

    def self.create_tag_builder(context, provider = nil)
      provider = provider ||
        provider_from_context(context) ||
        Rbexy.configuration.component_provider

      if provider
        ComponentTagBuilder.new(context, provider)
      else
        ActionView::Helpers::TagHelper::TagBuilder.new(context)
      end
    end

    def self.provider_from_context(context)
      if context.respond_to?(:rbexy_component_provider)
        context.rbexy_component_provider
      end
    end

    def initialize(component_provider = nil)
      @rbexy_tag = self.class.create_tag_builder(self, component_provider)
    end

    def evaluate(code)
      instance_eval(code)
    rescue => e
      e.set_backtrace(e.backtrace.map { |l| l.gsub("(eval)", "(rbx template string)") })
      raise e
    end
  end
end
