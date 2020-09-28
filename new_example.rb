require "bundler"
Bundler.require
require "active_support/inflector"
require "active_support/core_ext/string/strip"

template_string = <<-RBX.strip_heredoc.strip
  Hello "World"
  {true ? "is true" : "is false"}
RBX

puts "=============== Compiled ruby code ==============="
code = Rbexy.compile(template_string)
puts code

puts "=============== Result of eval ==============="
puts eval code

# Now we need a Runtime as well, that exposes some methods to the template ruby
# code.. somehow we need to merge the runtime with the context kinda like ActionView..
# module mixin? `include Rbexy::Runtime` in your context? In here we'll have `tag`
# helper...
