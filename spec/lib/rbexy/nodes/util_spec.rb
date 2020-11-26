RSpec.describe Rbexy::Nodes::Util do
  describe ".inject" do
    it "adds an element between every pair of given types" do
      original = [1, "hello", { foo: "bar" }, "world", 2, { baz: "bip" }, "!"]
      result = Rbexy::Nodes::Util.inject(original, builder: -> { "+" }, between: [Hash, String])
      expect(result).to eq [1, "hello", "+", { foo: "bar" }, "+", "world", 2, { baz: "bip" }, "+", "!"]
    end
  end
end
