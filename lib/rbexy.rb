require "rbexy/version"
require "active_support/inflector"
require "active_support/concern"
require "action_view/helpers/output_safety_helper"
require "action_view/helpers/capture_helper"
require "action_view/helpers/tag_helper"
require "action_view/context"

module Rbexy
  autoload :Lexer, "rbexy/lexer"
  autoload :Parser, "rbexy/parser"
  autoload :Nodes, "rbexy/nodes"
  autoload :Runtime, "rbexy/runtime"
  autoload :HashMash, "rbexy/hash_mash"
  autoload :ComponentContext, "rbexy/component_context"
  autoload :Configuration, "rbexy/configuration"
  autoload :ComponentResolver, "rbexy/component_resolver"
  autoload :Template, "rbexy/template"

  ContextNotFound = Class.new(StandardError)

  class << self
    def configure
      yield(configuration)
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def compile(template, element_resolver = Rbexy.configuration.element_resolver)
      tokens = Lexer.new(template, element_resolver).tokenize
      root = Parser.new(tokens).parse
      root.precompile.compile
    end

    def evaluate(template_string, runtime, element_resolver = Rbexy.configuration.element_resolver)
      runtime.evaluate compile(Template.new(template_string), element_resolver)
    end
  end
end
