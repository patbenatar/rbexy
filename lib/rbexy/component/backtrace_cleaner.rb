module Rbexy
  class Component
    class BacktraceCleaner
      attr_reader :backtrace

      def initialize(backtrace)
        @backtrace = backtrace
        @found_templates = {}
      end

      def call
        backtrace
          .reject(&method(:internal_implementation_detail?))
          .map(&method(:strip_rbx_internals_block_mention))
      end

      private

      attr_reader :found_templates

      def internal_implementation_detail?(line)
        if template = template_name_if_rbx_internals(line)
          redundant_internal_block?(line, template)
        else
          internal_method_call?(line)
        end
      end

      def internal_method_call?(line)
        line =~ /lib\/rbexy\/.*\.rb/ ||
          line =~ /lib\/action_view\/.*\.rb/ ||
          line =~ /lib\/active_support\/notifications\.rb/
      end

      def redundant_internal_block?(line, template)
        if found_templates[template]
          true
        else
          found_templates[template] = true
          false
        end
      end

      def strip_rbx_internals_block_mention(line)
        if template_name_if_rbx_internals(line)
          line.gsub(/block (\(\d+ levels\))? ?in /, "")
        else
          line
        end
      end

      def template_name_if_rbx_internals(line)
        if /\/(?<template>[^\/]*)\.rbx:\d+:in `(block |_)/ =~ line
          template
        end
      end
    end
  end
end
