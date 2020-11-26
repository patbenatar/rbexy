require "active_support/all"
require "action_view/helpers"
require "action_view/context"
require "action_view/buffers"

module Rbexy
  class Runtime
    include ActionView::Context
    include ActionView::Helpers::TagHelper
    include ViewContextHelper
    include ComponentContext

    def self.splat_attrs(attrs_hash)
      # TagBuilder requires a view_context arg, but it's only used in #tag_string.
      # Since all we need is #tag_options, we pass in a nil view_context.
      TagBuilder.new(nil).tag_options(attrs_hash).html_safe
    end

    def self.expr_out(*value)
      return if value.length == 0
      value = value.first

      value = html_safe_array?(value) ? value.join.html_safe : value
      [nil, false].include?(value) ? "" : value.to_s
    end

    def self.html_safe_array?(value)
      value.is_a?(Array) && value.all? { |v| v.respond_to?(:html_safe?) && v.html_safe? }
    end

    def evaluate(code)
      @output_buffer = ActionView::OutputBuffer.new
      instance_eval(code)
    rescue => e
      e.set_backtrace(e.backtrace.map { |l| l.gsub("(eval)", "(rbx template string)") })
      raise e
    end
  end
end
