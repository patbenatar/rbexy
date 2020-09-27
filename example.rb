require "bundler"
Bundler.require
require "active_support/inflector"
require "active_support/core_ext/string/strip"

require_relative "lib/rbexy"

template_string = <<-RBX.strip_heredoc.strip
  <div foo bar="baz" thing={["hey", "you"].join()}>
    <h1 {**splat_attrs}>Hello world</h1>
    Some words
    <p>Lorem ipsum</p>
    <input type="submit" value={@ivar_val} />
    <Button>the content</Button>
    <Forms.TextField />
  </div>
RBX

puts "### Tokenizing..."
tokens = Rbexy::Lexer.new(template_string).tokenize
tokens.each do |token|
  puts token.join(": ")
end

puts "### Parsing..."
template = Rbexy::Parser.new(tokens).parse
puts template

puts "### Compiling..."
class CompileContext
  def initialize
    @ivar_val = "ivar value"
  end

  def splat_attrs
    {
      attr1: "val1",
      attr2: "val2"
    }
  end
end

class Button
  def initialize(**attrs)
  end

  def render
    "<button class='myCustomButton'>#{yield.join("")}</button>"
  end
end

module Forms
  class TextField
    def initialize(**attrs)
    end

    def render
      "<input type='text' />"
    end
  end
end

class ComponentProvider
  def match?(name)
    find(name) != nil
  end

  def render(name, attrs, &block)
    find(name).new(**attrs).render(&block)
  end

  def find(name)
    ActiveSupport::Inflector.constantize(name.gsub(".", "::"))
  rescue NameError => e
    nil
  end
end

# html_compiler = Rbexy::HtmlCompiler.new(CompileContext.new)
component_compiler = Rbexy::ComponentCompiler.new(CompileContext.new, ComponentProvider.new)
puts template.compile(component_compiler)
