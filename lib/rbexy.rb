require "rbexy/version"

module Rbexy
  autoload :Lexer, "rbexy/lexer"
  autoload :Parser, "rbexy/parser"
  autoload :Nodes, "rbexy/nodes"
  autoload :HtmlRuntime, "rbexy/html_runtime"
  autoload :HashMash, "rbexy/hash_mash"

  def self.compile(template_string)
    tokens = Rbexy::Lexer.new(template_string).tokenize
    template = Rbexy::Parser.new(tokens).parse
    template.compile
  end

  def self.evaluate(template_string, runtime)
    runtime.evaluate compile(template_string)
  end
end
