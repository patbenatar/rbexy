require "bundler"
Bundler.require

require "active_support/all"
require "action_view/helpers"
require "action_view/context"
require "action_view/buffers"

template_string = <<-RBX
<div>
  <h1 {**{ class: "myClass" }} {**splat_attrs}>Hello world</h1>
  <div {**{ class: "myClass" }}></div>
  Some words
  <p>Lorem ipsum</p>
  <input type="submit" value={@ivar_val} disabled />
  {true && <p>Is true</p>}
  {false && <p>Is false</p>}
  {true ? <p {**{ class: "myClass" }}>Ternary is {'true'.upcase}</p> : <p>Ternary is false</p>}
  <Button prop1="val1" prop2={true && "val2"} multi-word-prop="value">the content</Button>
  <Forms.TextField label={->(n) { <label id={n}>Something</label> }} note={<p>the note</p>} />
  <ul>
    {["hi", "there", "nick"].map { |val| <li>{val}</li> }}
  </ul>
</div>
RBX

module Components
  class ButtonComponent
    def initialize(prop1:, prop2:, multi_word_prop:)
      @prop1 = prop1
      @prop2 = prop2
      @multi_word_prop = multi_word_prop
    end

    def render
      # Render it yourself, call one of Rails view helpers (link_to,
      # content_tag, etc), or use a template file. Be sure to render
      # children by yielding to the given block.
      "<button class=\"#{[@prop1, @prop2, @multi_word_prop].join("-")}\">#{yield}</button>"
    end
  end

  module Forms
    class TextFieldComponent
      def initialize(label:, note:, **attrs)
        @label = label
        @note = note
      end

      def render
        "#{@label.call(2)} <input type=\"text\" />#{@note}"
      end
    end
  end
end

class ComponentProvider
  def match?(name)
    find(name) != nil
  end

  def render(context, name, **attrs, &block)
    props = attrs.transform_keys { |k| ActiveSupport::Inflector.underscore(k.to_s).to_sym }
    find(name).new(**props).render(&block)
  end

  private

  def find(name)
    ActiveSupport::Inflector.constantize("Components::#{name}Component")
  rescue NameError => e
    raise e unless e.message =~ /constant/
    nil
  end
end

class MyRuntime < Rbexy::Runtime
  def initialize(component_provider)
    super(component_provider)
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
