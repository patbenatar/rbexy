class PerfTest::FastComponent # < Rbexy::Component
  # include ActionView::Context
  # TEMPLATE = "@output_buffer.safe_concat('<h1>Hello component</h1>'.freeze);@output_buffer.to_s;".freeze

  def initialize(view_context)
    # @compiled = Rbexy.compile(Rbexy::Template.new("<h1>Hello component</h1>"))
    # @runtime = Rbexy::Runtime.new
    @output_buffer = ActionView::OutputBuffer.new
    # @output_buffer = view_context.instance_variable_get(:@output_buffer)
  end

  def render_in
    # @runtime.evaluate(@compiled)
    # @compiled
    # instance_eval(TEMPLATE)
    template
    # instance_eval(@compiled)
    # "<h1>Hello component</h1>"
    # tag.h2 "Hello component"
  end

  def template
    @output_buffer.safe_concat('<h1>Hello component</h1>'.freeze);@output_buffer.to_s;
  end
end
