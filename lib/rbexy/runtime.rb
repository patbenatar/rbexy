module Rbexy
  class Runtime
    include ActionView::Context
    include ActionView::Helpers::TagHelper
    include ComponentContext

    def self.tag_builder
      @tag_builder ||= TagBuilder.new(new)
    end

    def self.splat_attrs(attrs_hash)
      tag_builder.tag_options(attrs_hash)&.html_safe
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
      e.set_backtrace(e.backtrace.map { |l| l.gsub(/\(eval( at [^)]+)?\)/, "(rbx template string)") })
      raise e
    end
  end
end
