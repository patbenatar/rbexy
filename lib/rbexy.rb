require "rbexy/version"

module Rbexy
  autoload :Lexer, "rbexy/lexer"
  autoload :Parser, "rbexy/parser"
  autoload :Nodes, "rbexy/nodes"
  autoload :HtmlCompiler, "rbexy/html_compiler"
  autoload :ComponentCompiler, "rbexy/component_compiler"
  autoload :HashMash, "rbexy/hash_mash"

  def self.compile(template_string, compiler)
    tokens = Rbexy::Lexer.new(template_string).tokenize
    template = Rbexy::Parser.new(tokens).parse
    template.compile(compiler)
  end
end
