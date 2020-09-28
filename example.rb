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

class MyRuntime < Rbexy::HtmlRuntime
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
puts MyRuntime.new.evaluate(code)
