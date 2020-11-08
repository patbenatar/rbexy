require "active_support/core_ext/string/strip"
require "active_support/all"
require "action_view/helpers"
require "action_view/context"
require "action_view/buffers"

RSpec.describe Rbexy do
  it "has a version number" do
    expect(Rbexy::VERSION).not_to be nil
  end

  it "handles a bunch of html" do
    template_string = <<-RBX.strip_heredoc.strip
      <!DOCTYPE html>
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

    class Runtime < Rbexy::Runtime
      def initialize
        super
        @ivar_val = "ivar value"
      end

      def splat_attrs
        {
          attr1: "val1",
          attr2: "val2"
        }
      end
    end

    result = Rbexy.evaluate(template_string, Runtime.new)

    expected = <<-OUTPUT.strip_heredoc.strip
      <!DOCTYPE html>
      <div foo="" bar="baz" thing="heyyou">
        <h1 class="myClass" attr1="val1" attr2="val2">Hello world</h1>
        <div class="myClass"></div>
        Some words
        <p>Lorem ipsum</p>
        <input type="submit" value="ivar value" disabled="disabled">
        <p>Is true</p>\n  \n        <p class="myClass">Ternary is TRUE</p>
      </div>
    OUTPUT

    expect(result).to eq expected
  end

  it "handles html with multiline tags" do
    template_string = <<-RBX.strip_heredoc.strip
      <div
        foo
        bar="baz"
        thing={["hey", "you"].join()}>
        <h1
          {**{ class: "myClass" }}>Hello world</h1>
      </div>
    RBX

    result = Rbexy.evaluate(template_string, Rbexy::Runtime.new)

    expected = <<-OUTPUT.strip_heredoc.strip
      <div foo="" bar="baz" thing="heyyou">
        <h1 class="myClass">Hello world</h1>
      </div>
    OUTPUT

    expect(result).to eq expected
  end

  it "handles custom components with html" do
    module Components
      class ButtonComponent
        def initialize(context, prop1:, prop2:)
          @context = context
          @prop1 = prop1
          @prop2 = prop2
        end

        def render(&block)
          # Render it yourself, call one of Rails view helpers (link_to,
          # content_tag, etc), or use a template file. Be sure to render
          # children by capturing the given block.
          "<button class=\"#{[@prop1, @prop2].join("-")}\">#{@context.capture(&block)}</button>"
        end
      end

      module Forms
        class TextFieldComponent
          def initialize(context, **attrs)
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

      def render(context, name, **attrs, &block)
        find(name).new(context, **attrs).render(&block)
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

    template_string = <<-RBX.strip_heredoc.strip
      <div>
        <h1>Hello world</h1>
        <Button prop1="val1" prop2={true && "val2"}>the content</Button>
        <Forms.TextField />
      </div>
    RBX

    result = Rbexy.evaluate(template_string, MyRuntime.new(ComponentProvider.new))

    expected = <<-OUTPUT.strip_heredoc.strip
      <div>
        <h1>Hello world</h1>
        <button class="val1-val2">the content</button>
        <input type="text" />
      </div>
    OUTPUT

    expect(result).to eq expected
  end

  it "handles loops with blocks" do
    template_string = <<-RBX.strip_heredoc.strip
      <ul>
        {["Hello", "world"].map { |v| <li>{v}</li> }}
      </ul>
    RBX

    result = Rbexy.evaluate(template_string, Rbexy::Runtime.new)

    expected = <<-OUTPUT.strip_heredoc.strip
      <ul>
        <li>Hello</li><li>world</li>
      </ul>
    OUTPUT

    expect(result).to eq expected
  end

  it "doesn't hang when encountering boolean expression void tag at end of template" do
    template_string = <<-RBX.strip_heredoc.strip
      <div>
        <h1>Hello world</h1>
      </div>
      {true && <br />}
    RBX

    result = ""

    expect do
      Timeout::timeout(1) do
        result = Rbexy.evaluate(template_string, Rbexy::Runtime.new)
      end
    end.not_to raise_error

    expect(result).to eq <<-RESULT.strip_heredoc.strip
      <div>
        <h1>Hello world</h1>
      </div>
      <br>
    RESULT
  end

  context "compiled code maintains the same line numbers as the template so error messages are useful" do
    examples = [
      ["{an_undefined_method}", 1],
      ["Hello {an_undefined_method}", 1],
      ["Hello <input attr={an_undefined_method} />", 1],
      ["<input attr={an_undefined_method} />", 1],
      ["Hello {true && \"hey\"} {an_undefined_method}", 1],
      ["Hello {true && \"hey\"} <input attr={an_undefined_method} />", 1],
      [
        <<-RBX.strip_heredoc,
          Hello
          {an_undefined_method}
        RBX
        2
      ],
      [
        <<-RBX.strip_heredoc,
          Hello
          {true && "hey"}
          <div>
            <input attr={an_undefined_method} />
          </div>
        RBX
        4
      ],
      [
        <<-RBX.strip_heredoc,
          <input
            foo="bar"
            baz={an_undefined_method}
          />
        RBX
        3
      ]
    ]

    examples.each do |(template_string, expected_line_number)|
      it "raises on line #{expected_line_number} for `#{template_string}`" do
        expect { Rbexy.evaluate(template_string, Rbexy::Runtime.new) }
          .to raise_error do |error|
            expect(error).to be_a NameError
            expect(error.backtrace.first)
              .to include "(rbx template string):#{expected_line_number}"
          end
      end
    end
  end

  it "escapes unwanted html" do
    template_string = <<-RBX.strip_heredoc.strip
      <div>
        <h1>Here it comes</h1>
        <p>{@some_ugc_string}</p>
      </div>
    RBX

    class MyRuntime < Rbexy::Runtime
      def initialize(*args)
        super
        @some_ugc_string = "<p>html here</p>"
      end
    end

    result = Rbexy.evaluate(template_string, MyRuntime.new)

    expected = <<-OUTPUT.strip_heredoc.strip
      <div>
        <h1>Here it comes</h1>
        <p>&lt;p&gt;html here&lt;/p&gt;</p>
      </div>
    OUTPUT

    expect(result).to eq expected
  end
end
