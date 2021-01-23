RSpec.describe Rbexy::Nodes::ExpressionGroup do
  describe "precompile->compile" do
    it "doesn't try to output a debugger and adds a newline to ensure binding is in the right place" do
      subject = described_class.new([Rbexy::Nodes::Expression.new("debugger")])
      result = subject.precompile.map(&:compile).join
      expect(result).to eq "debugger\n"
    end

    it "doesn't try to output a binding.pry and adds a newline to ensure binding is in the right place" do
      subject = described_class.new([Rbexy::Nodes::Expression.new("binding.pry")])
      result = subject.precompile.map(&:compile).join
      expect(result).to eq "binding.pry\n"
    end

    it "doesn't care about leading or trailing whitespace" do
      subject = described_class.new([Rbexy::Nodes::Expression.new("   binding.pry   ")])
      result = subject.precompile.map(&:compile).join
      expect(result).to eq "   binding.pry   \n"
    end
  end
end
