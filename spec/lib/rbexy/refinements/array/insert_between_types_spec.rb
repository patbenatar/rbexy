RSpec.describe Rbexy::Refinements::Array::InsertBetweenTypes do
  using Rbexy::Refinements::Array::InsertBetweenTypes

  it "adds an element between every pair of given types" do
    original = [1, "hello", { foo: "bar" }, "world", 2, { baz: "bip" }, "!"]
    result = original.insert_between_types(Hash, String) { "+" }
    expect(result).to eq [1, "hello", "+", { foo: "bar" }, "+", "world", 2, { baz: "bip" }, "+", "!"]
  end
end
