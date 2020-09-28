require "bundler"
Bundler.require

# require "active_support/inflector"
require "active_support/all"
require "action_view/helpers"
require "action_view/context"
require "action_view/buffers"

template_string = <<-RBX
Hello "World"
{true ? "is true" : "is false"}
<div>
  <h1 class="myClass">Content</h1>
</div>
<br />
RBX

# Now we need a Runtime as well, that exposes some methods to the template ruby
# code.. somehow we need to merge the runtime with the context kinda like ActionView..
# module mixin? `include Rbexy::Runtime` in your context? In here we'll have `tag`
# helper...
class Runtime
  include ActionView::Context
  include ActionView::Helpers::TagHelper

  def run(code)
    instance_eval(code)
  end
end

puts "=============== Compiled ruby code ==============="
code = Rbexy.compile(template_string)
puts code

puts "=============== Result of eval ==============="
puts Runtime.new.run(code)
