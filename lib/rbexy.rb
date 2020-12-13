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
  autoload :ComponentContext, "rbexy/component_context"
  autoload :Configuration, "rbexy/configuration"
  autoload :ComponentResolver, "rbexy/component_resolver"
  autoload :Template, "rbexy/template"
  autoload :Refinements, "rbexy/refinements"
  autoload :ASTTransformer, "rbexy/ast_transformer"

  ContextNotFound = Class.new(StandardError)

  class << self
    def configure
      yield(configuration)
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def compile(template, context = build_default_compile_context(template))
      tokens = Lexer.new(template, context.element_resolver).tokenize
      root = Parser.new(tokens).parse
      root.inject_compile_context(context)
      root.transform!
      root.precompile.compile
    end

    def evaluate(template_string, runtime = Rbexy::Runtime.new)
      runtime.evaluate compile(Template.new(template_string))
    end

    def build_default_compile_context(template)
      OpenStruct.new(
        template: template,
        element_resolver: configuration.element_resolver,
        ast_transformer: configuration.transforms
      )
    end
  end
end
