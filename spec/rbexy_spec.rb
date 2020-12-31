require "active_support/core_ext/string/strip"
require "active_support/all"
require "action_view/helpers"
require "action_view/context"
require "action_view/buffers"

RSpec.describe Rbexy do
  it "has a version number" do
    expect(Rbexy::VERSION).not_to be nil
  end

  it "handles simple nested html" do
    template_string = <<-RBX.strip_heredoc.strip
      <div>
        <h1>Hello world</h1>
        <p>Welcome to Rbexy</p>
      </div>
    RBX

    result = Rbexy.evaluate(template_string)

    expected = <<-OUTPUT.strip_heredoc.strip
      <div>
        <h1>Hello world</h1>
        <p>Welcome to Rbexy</p>
      </div>
    OUTPUT

    expect(result).to eq expected
  end

  it "handles html with string attributes" do
    template_string = <<-RBX.strip_heredoc.strip
      <h1 class="my-class" id="the-id">Hello world</h1>
    RBX

    result = Rbexy.evaluate(template_string)

    expected = <<-OUTPUT.strip_heredoc.strip
      <h1 class="my-class" id="the-id">Hello world</h1>
    OUTPUT

    expect(result).to eq expected
  end

  it "handles html with expression attributes" do
    template_string = <<-RBX.strip_heredoc.strip
      <h1 class={true && "my-class"} id={false ? "is-true" : "is-false"}>Hello world</h1>
    RBX

    result = Rbexy.evaluate(template_string)

    expected = <<-OUTPUT.strip_heredoc.strip
      <h1 class="my-class" id="is-false">Hello world</h1>
    OUTPUT

    expect(result).to eq expected
  end

  it "does not self-close child-less tags" do
    expect(Rbexy.evaluate("<div></div>"))
      .to eq "<div></div>"
  end

  it "explicitly closes non-void self-closing tags (valid as per JSX but invalid HTML)" do
    expect(Rbexy.evaluate("<div />"))
      .to eq "<div></div>"
  end

  it "does not close void tags" do
    expect(Rbexy.evaluate("<br />"))
      .to eq "<br>"
  end

  it "allows newlines in html tags" do
    template_string = <<-RBX.strip_heredoc.strip
      <div
        class="foo"
      >
      </div>
    RBX

    result = Rbexy.evaluate(template_string)

    expected = <<-OUTPUT.strip_heredoc.strip
      <div
       class="foo"
      >
      </div>
    OUTPUT

    expect(result).to eq expected
  end

  it "handles custom components" do
    class ButtonComponent
      def initialize(context, **props)
      end

      def render
        "<button>"
      end
    end

    expect(Rbexy.evaluate("<Button />"))
      .to eq "<button>"
  end

  it "passes objects through to custom components" do
    class AvatarComponent
      def initialize(context, user:)
        @user = user
      end

      def render
        "<img src=\"#{@user.avatar_url}\">"
      end
    end

    expect(Rbexy.evaluate("<Avatar user={Struct.new(:avatar_url).new('the_url')} />"))
      .to eq '<img src="the_url">'
  end

  it "handles custom components with html children" do
    class ContainerComponent
      def initialize(context, **props)
      end

      def render
        "<div>#{yield}</div>"
      end
    end

    template_string = <<-RBX.strip_heredoc.strip
      <Container>
        <h1>Hello world</h1>
      </Container>
    RBX

    result = Rbexy.evaluate(template_string)

    expected = <<-OUTPUT.strip_heredoc.strip
      <div>
        <h1>Hello world</h1>
      </div>
    OUTPUT

    expect(result).to eq expected
  end

  it "underscores multi-word attrs when passing to custom component" do
    class ButtonComponent
      def initialize(context, the_class_name:)
        @the_class_name = the_class_name
      end

      def render
        "<button class=\"#{@the_class_name}\">"
      end
    end

    expect(Rbexy.evaluate('<Button the-class-name="foo" />'))
      .to eq '<button class="foo">'
  end

  it "handles declarations" do
    expect(Rbexy.evaluate("<!DOCTYPE html>"))
      .to eq "<!DOCTYPE html>"
  end

  it "handles splat attrs on html elements" do
    expect(Rbexy.evaluate('<div {**{class: "my-class"}}></div>'))
      .to eq '<div class="my-class"></div>'
  end

  it "handles splat attrs on custom components" do
    class ButtonComponent
      def initialize(context, attr1:, attr2:)
        @attr1 = attr1
        @attr2 = attr2
      end

      def render
        "<button attr1=\"#{@attr1}\" attr2=\"#{@attr2}\"></button>"
      end
    end

    MyRuntime = Class.new(Rbexy::Runtime) do
      def splat_attrs
        {
          attr1: "val1",
          attr2: "val2"
        }
      end
    end

    expect(Rbexy.evaluate('<Button {**splat_attrs} />', MyRuntime.new))
      .to eq '<button attr1="val1" attr2="val2"></button>'
  end

  it "handles multi-word attrs on html elements" do
    expect(Rbexy.evaluate('<form accept-charset="utf-8" data-foo-bar="baz"></form>'))
      .to eq '<form accept-charset="utf-8" data-foo-bar="baz"></form>'
  end

  it "handles boolean attrs on html elements" do
    expect(Rbexy.evaluate('<button disabled />'))
      .to eq '<button disabled=""></button>'
  end

  it "handles boolean expressions with html elements" do
    expect(Rbexy.evaluate('{true && <div></div>}'))
      .to eq '<div></div>'
  end

  it "handles boolean expressions with custom components" do
    class ButtonComponent
      def initialize(*)
      end

      def render
        "<button />"
      end
    end

    expect(Rbexy.evaluate('{true && <Button />}'))
      .to eq '<button />'
  end

  it "handles ternary expressions" do
    expect(Rbexy.evaluate('{true ? <div></div> : <span></span>}'))
      .to eq '<div></div>'
  end

  it "handles ternary expressions with sub-expressions" do
    expect(Rbexy.evaluate('{true ? <div {**{class: "the-class"}}></div> : <span></span>}'))
      .to eq '<div class="the-class"></div>'
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

    compiled = Rbexy.compile(Rbexy::Template.new(template_string))
    result = profile { Runtime.new.evaluate(compiled) }

    expected = <<-OUTPUT.strip_heredoc.strip
      <!DOCTYPE html>
      <div foo="" bar="baz" thing="heyyou">
        <h1 class="myClass" attr1="val1" attr2="val2">Hello world</h1>
        <div class="myClass"></div>
        Some words
        <p>Lorem ipsum</p>
        <input type="submit" value="ivar value" disabled="">
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

    result = Rbexy.evaluate(template_string)

    expected = <<-OUTPUT.strip_heredoc.strip
      <div
       foo=""
       bar="baz"
       thing="heyyou">
        <h1
       class="myClass">Hello world</h1>
      </div>
    OUTPUT

    expect(result).to eq expected
  end

  it "handles custom components with html" do
    class ButtonComponent
      def initialize(context, prop1:, prop2:)
        @prop1 = prop1
        @prop2 = prop2
      end

      def render
        "<button class=\"#{[@prop1, @prop2].join("-")}\">#{yield}</button>"
      end
    end

    module Forms
      class TextFieldComponent
        def initialize(context, **props)
        end

        def render
          "<input type=\"text\" />"
        end
      end
    end

    class MyRuntime < Rbexy::Runtime
      def initialize
        super
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

    compiled = Rbexy.compile(Rbexy::Template.new(template_string))
    result = profile { MyRuntime.new.evaluate(compiled) }

    expected = <<-OUTPUT.strip_heredoc.strip
      <div>
        <h1>Hello world</h1>
        <button class="val1-val2">the content</button>
        <input type="text" />
      </div>
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
        result = Rbexy.evaluate(template_string)
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
        expect { Rbexy.evaluate(template_string) }
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

  describe "array expressions" do
    it "compiles and joins rbx returned from loops like `map`" do
      template_string = <<-RBX.strip_heredoc.strip
        <ul>
          {["Hello", "world"].map { |v| <li>{v}</li> }}
        </ul>
      RBX

      result = Rbexy.evaluate(template_string)

      expected = <<-OUTPUT.strip_heredoc.strip
        <ul>
          <li>Hello</li><li>world</li>
        </ul>
      OUTPUT

      expect(result).to eq expected
    end

    it "allows newlines in loop html tags" do
      template_string = <<-RBX.strip_heredoc.strip
        <ul>
          {["Hello", "world"].map do |v|
            <li
              class="foo"
            >
              {v}
            </li>
          end}
        </ul>
      RBX

      result = Rbexy.evaluate(template_string)

      expected = <<-OUTPUT.strip_heredoc.strip
        <ul>
          <li
         class="foo"
        >
              Hello
            </li><li
         class="foo"
        >
              world
            </li>
        </ul>
      OUTPUT

      expect(result).to eq expected
    end

    it "allows newlines in loop custom component tags" do
      class ButtonComponent
        def initialize(*, **kwargs)
          @class = kwargs[:class]
        end

        def render
          "<button class=\"#{@class}\"></button>"
        end
      end

      template_string = <<-RBX.strip_heredoc.strip
        <div>
          {["Hello", "world"].map { |v| <Button
            class="foo"
            /> }}
        </div>
      RBX

      result = Rbexy.evaluate(template_string)

      expected = <<-OUTPUT.strip_heredoc.strip
        <div>
          <button class="foo"></button><button class="foo"></button>
        </div>
      OUTPUT

      expect(result).to eq expected
    end

    it "allows loops within sub-expressions" do
      template_string = <<-RBX.strip_heredoc.strip
        {true && <ul>
          {["Hello", "world"].map { |v| <li class="foo">{v}</li> }}
        </ul>}
      RBX

      result = Rbexy.evaluate(template_string)

      expected = <<-OUTPUT.strip_heredoc.strip
        <ul>
          <li class="foo">Hello</li><li class="foo">world</li>
        </ul>
      OUTPUT

      expect(result).to eq expected
    end

    it "allows html>custom hierarchies within loops" do
      class ButtonComponent
        def initialize(*)
        end

        def render
          "<button></button>"
        end
      end

      template_string = <<-RBX.strip_heredoc.strip
        <ul>
          {["Hello", "world"].map { |v| <li>{v} <Button /></li> }}
        </ul>
      RBX

      result = Rbexy.evaluate(template_string)

      expected = <<-OUTPUT.strip_heredoc.strip
        <ul>
          <li>Hello <button></button></li><li>world <button></button></li>
        </ul>
      OUTPUT

      expect(result).to eq expected
    end

    it "explicitly coerces expression values in attributes to strings" do
      expect(Rbexy.evaluate("{[1, 2].map { <div id={BigDecimal('10')}></div> }}"))
        .to eq '<div id="10.0"></div><div id="10.0"></div>'
    end

    it "explicitly coerces expression values in children to strings" do
      expect(Rbexy.evaluate("{[1, 2].map { <div>{BigDecimal('10')}</div> }}"))
        .to eq '<div>10.0</div><div>10.0</div>'
    end

    it "does not try to join arbitrary arrays" do
      template_string = <<-RBX.strip_heredoc.strip
        {["Hello", "world"]}
      RBX

      result = Rbexy.evaluate(template_string)

      expected = <<-OUTPUT.strip_heredoc.strip
        [&quot;Hello&quot;, &quot;world&quot;]
      OUTPUT

      expect(result).to eq expected
    end
  end

  context "with AST transforms" do
    after(:each) { Rbexy.configuration.transforms.clear! }

    it "allows transforms to manipulate html attributes" do
      Rbexy.configuration.transforms.register(Rbexy::Nodes::HTMLAttr) do |node, context|
        if node.name == "class" && node.value.is_a?(Rbexy::Nodes::Text)
          node.value.content = "#{node.value.content}-t"
        end
      end

      expect(Rbexy.evaluate('<h1 class="myClass" id="myId">Hello transforms</h1>'))
        .to eq '<h1 class="myClass-t" id="myId">Hello transforms</h1>'
    end

    it "allows transforms to manipulate component props" do
      Rbexy.configuration.transforms.register(Rbexy::Nodes::ComponentProp) do |node, context|
        if node.name == "id" && node.value.is_a?(Rbexy::Nodes::Text)
          node.value.content = "#{node.value.content}-t"
        end
      end

      class ButtonComponent
        def initialize(context, id:)
          @id = id
        end

        def render
          "<button id=\"#{@id}\">"
        end
      end

      expect(Rbexy.evaluate('<Button id="myId" />'))
        .to eq '<button id="myId-t">'
    end
  end
end
