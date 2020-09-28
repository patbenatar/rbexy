require "bundler"
Bundler.require

require "active_support/all"
require "action_view/helpers"
require "action_view/context"
require "action_view/buffers"

template_string = <<-RBX
<div foo bar="baz" thing={["hey", "you"].join()}>
  <h1 {**{ class: "myClass" }} {**splat_attrs}>Hello world</h1>
  <div {**{ class: "myClass" }}></div>
  Some words
  <p>Lorem ipsum</p>
  <input type="submit" value={@ivar_val} disabled />
  {true && <p>Is true</p>}
  {false && <p>Is false</p>}
  {true ? <p {**{ class: "myClass" }}>Ternary is {'true'.upcase}</p> : <p>Ternary is false</p>}
</div>
RBX

module Components
  class ButtonComponent < ViewComponent::Base
    def initialize(**attrs)
    end

    def render
      # Render it yourself, call one of Rails view helpers (link_to,
      # content_tag, etc), or use a template file. Be sure to render
      # children by yielding to the given block.
      "<button class=\"myCustomButton\">#{yield}</button>"
    end
  end

  module Forms
    class TextFieldComponent < ViewComponent::Base
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
    ActiveSupport::Inflector.constantize(name.gsub(".", "::"))
  rescue NameError => e
    nil
  end
end

class MyRuntime < Rbexy::ComponentRuntime
  def initialize
    @ivar_val = "ivar value"
  end

  def splat_attrs
    {
      key1: "val1",
      key2: "val2"
    }
  end
end

puts "=============== Compiled ruby code ==============="
code = Rbexy.compile(template_string)
puts code

puts "=============== Result of eval ==============="
puts MyRuntime.new(ComponentProvider.new).evaluate(code)
