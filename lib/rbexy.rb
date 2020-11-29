require "rbexy/version"

module Rbexy
  autoload :Lexer, "rbexy/lexer"
  autoload :Parser, "rbexy/parser"
  autoload :Nodes, "rbexy/nodes"
  autoload :Runtime, "rbexy/runtime"
  autoload :HashMash, "rbexy/hash_mash"
  # TODO: won't need this anymore
  autoload :ViewContextHelper, "rbexy/view_context_helper"
  autoload :ComponentContext, "rbexy/component_context"
  autoload :Configuration, "rbexy/configuration"
  autoload :ComponentResolver, "rbexy/component_resolver"

  ContextNotFound = Class.new(StandardError)

  class << self
    def configure
      yield(configuration)
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def compile(template_string, element_resolver = Rbexy.configuration.element_resolver)
      tokens = Lexer.new(template_string, element_resolver).tokenize
      root = Parser.new(tokens).parse
      root.precompile.compile
    end

    def evaluate(template_string, runtime, element_resolver = Rbexy.configuration.element_resolver)
      runtime.evaluate compile(template_string, element_resolver)
    end
  end
end
