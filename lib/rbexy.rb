require "rbexy/version"

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

    # TODO: modify this to receive an optional template: object
    # also change the options args to be kwargs, including element_resolver
    # maybe rename ComponentResolver to ElementResolver ??
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
