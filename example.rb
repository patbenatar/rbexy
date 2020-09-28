require "bundler"
Bundler.require

require "active_support/all"
require "action_view/helpers"
require "action_view/context"
require "action_view/buffers"

template_string = <<-RBX
<ul>
  {["Hello", "world"].map { |v| <li>{v}</li> }}
</ul>
RBX

module Components
  class ButtonComponent
    def initialize(prop1:, prop2:)
      @prop1 = prop1
      @prop2 = prop2
    end

    def render
      # Render it yourself, call one of Rails view helpers (link_to,
      # content_tag, etc), or use a template file. Be sure to render
      # children by yielding to the given block.
      "<button class=\"#{[@prop1, @prop2].join("-")}\">#{yield}</button>"
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
    ActiveSupport::Inflector.constantize("Components::#{name}Component")
  rescue NameError => e
    raise e unless e.message =~ /constant/
    nil
  end
end

class MyRuntime < Rbexy::ComponentRuntime
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
