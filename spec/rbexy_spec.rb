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

    class Runtime
      include ActionView::Context
      include ActionView::Helpers::TagHelper

      def initialize
        @ivar_val = "ivar value"
      end

      def evaluate(code)
        instance_eval(code)
      end

      def splat_attrs
        {
          attr1: "val1",
          attr2: "val2"
        }
      end
    end

    code = Rbexy.compile(template_string)
    result = Runtime.new.evaluate(code)

    expected = <<-OUTPUT.strip_heredoc.strip
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
end
