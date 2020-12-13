RSpec.describe Rbexy::Nodes::HTMLAttr do
  context "with AST transforms" do
    it "allows the registered transforms to mutate the node" do
      transformer = Rbexy::ASTTransformer.new
      transformer.register(Rbexy::Nodes::HTMLAttr) { |node, context| node.name = "#{node.name}-t1" }
      transformer.register(Rbexy::Nodes::HTMLAttr) { |node, context| node.name = "#{node.name}-t2" }

      subject = Rbexy::Nodes::HTMLAttr.new("name", "value")
      subject.inject_compile_context(OpenStruct.new(ast_transformer: transformer))

      expect { subject.transform! }
        .to change { subject.name }.from("name").to("name-t1-t2")
    end
  end
end
