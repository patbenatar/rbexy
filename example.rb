require "bundler"
Bundler.require
require "active_support/inflector"
require "active_support/core_ext/string/strip"

template_string = <<-RBX.strip_heredoc.strip
  <div foo bar="baz" thing={["hey", "you"].join()}>
    <h1 {**{ class: "myClass" }} {**splat_attrs}>Hello world</h1>
    <div {**{ class: "myClass" }}></div>
    Some words
    <p>Lorem ipsum</p>
    <input type="submit" value={@ivar_val} disabled />
    <Button>the content</Button>
    <Forms.TextField />
    {true && <p>Is true</p>}
    {false && <p>Is false</p>}
    {true ? <p {**{ class: "myClass" }}>Ternary is {'true'.upcase}</p> : <p>Ternary is false</p>}
  </div>
RBX

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

module Components
  class ButtonComponent
    def initialize(**attrs)
    end

    def render
      "<button class=\"myCustomButton\">#{yield}</button>"
    end
  end

  module Forms
    class TextFieldComponent
      def initialize(**attrs)
      end

      def render
        "<input type=\"text\" />"
      end
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
    ActiveSupport::Inflector.constantize("Components::#{name.gsub(".", "::")}Component")
  rescue NameError => e
    nil
  end
end

# html_compiler = Rbexy::HtmlCompiler.new(CompileContext.new)
component_compiler = Rbexy::ComponentCompiler.new(CompileContext.new, ComponentProvider.new)
puts Rbexy.compile(template_string, component_compiler)
