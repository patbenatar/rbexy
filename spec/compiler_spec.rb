require "active_support/core_ext/string/strip"

RSpec.describe "rbx->ruby integration tests" do
  describe "debuggers" do
    it "compiles them to quiet output and adds a newline so the binding isn't placed into the output_buffer call" do
      template_string = <<-RBX.strip_heredoc
        {binding.pry}
      RBX

      result = Rbexy.compile(Rbexy::Template.new(template_string))
      expect(result).to eq "binding.pry\n@output_buffer.safe_concat('\n'.freeze);@output_buffer.to_s"
    end

    it "works for debuggers inside html tags as well" do
      template_string = <<-RBX.strip_heredoc
        <h1>
          {binding.pry}
        </h1>
      RBX

      result = Rbexy.compile(Rbexy::Template.new(template_string))
      expect(result).to eq "@output_buffer.safe_concat('<h1>\n  '.freeze);binding.pry\n@output_buffer.safe_concat('\n</h1>\n'.freeze);@output_buffer.to_s"
    end
  end
end
