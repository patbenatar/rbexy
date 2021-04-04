RSpec.describe Rbexy::Nodes::Util do
  describe ".escape_string" do
    it "escapes single quotes" do
      result = described_class.escape_string("You're cool, eh?")
      expect(result).to eq "You\\'re cool, eh?"
    end
  end
end
