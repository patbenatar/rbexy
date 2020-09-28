require "bundler"
Bundler.require

# require "active_support/inflector"
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

# Now we need a Runtime as well, that exposes some methods to the template ruby
# code.. somehow we need to merge the runtime with the context kinda like ActionView..
# module mixin? `include Rbexy::Runtime` in your context? In here we'll have `tag`
# helper...
class Runtime
  include ActionView::Context
  include ActionView::Helpers::TagHelper

  def evaluate(code)
    instance_eval(code)
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
puts Runtime.new.evaluate(code)
