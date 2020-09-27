RSpec.describe Rbexy::Parser do
  it "handles :TEXT" do
    subject = Rbexy::Parser.new([[:TEXT, "Hello world"]])
    result = subject.parse.children
    expect(result.first).to be_a Rbexy::Nodes::Text
    expect(result.first.content).to eq "Hello world"
  end

  it "parses expressions" do
    subject = Rbexy::Parser.new([
      [:OPEN_EXPRESSION],
      [:EXPRESSION, "thing = 'bar'"],
      [:CLOSE_EXPRESSION],
    ])
    result = subject.parse.children
    expect(result.first).to be_a Rbexy::Nodes::Expression
    expect(result.first.content).to eq "thing = 'bar'"
  end

  it "parses named tags" do
    subject = Rbexy::Parser.new([
      [:OPEN_TAG_DEF],
      [:TAG_NAME, "div"],
      [:CLOSE_TAG_DEF],
      [:OPEN_TAG_END],
      [:CLOSE_TAG_END]
    ])
    result = subject.parse.children
    expect(result.first).to be_a Rbexy::Nodes::XmlNode
    expect(result.first.name).to eq "div"
  end

  it "raises if tag is missing a name" do
    subject = Rbexy::Parser.new([
      [:OPEN_TAG_DEF],
      [:CLOSE_TAG_DEF],
      [:OPEN_TAG_END],
      [:CLOSE_TAG_END]
    ])
    expect { subject.parse }.to raise_error Rbexy::Parser::ParseError
  end

  it "raises if tag is missing an end" do
    subject = Rbexy::Parser.new([
      [:OPEN_TAG_DEF],
      [:TAG_NAME, "div"],
      [:CLOSE_TAG_DEF]
    ])
    expect { subject.parse }.to raise_error Rbexy::Parser::ParseError
  end

  it "parses tag attributes" do
    subject = Rbexy::Parser.new([
      [:OPEN_TAG_DEF],
      [:TAG_NAME, "div"],
      [:OPEN_ATTRS],
      [:ATTR_NAME, "foo"],
      [:ATTR_NAME, "bar"],
      [:OPEN_ATTR_VALUE],
      [:TEXT, "baz"],
      [:CLOSE_ATTR_VALUE],
      [:ATTR_NAME, "thing"],
      [:OPEN_ATTR_VALUE],
      [:OPEN_EXPRESSION],
      [:EXPRESSION, "exprValue"],
      [:CLOSE_EXPRESSION],
      [:CLOSE_ATTR_VALUE],
      [:CLOSE_ATTRS],
      [:CLOSE_TAG_DEF],
      [:OPEN_TAG_END],
      [:CLOSE_TAG_END]
    ])

    div = subject.parse.children.first
    expect(div).to be_a Rbexy::Nodes::XmlNode
    expect(div.attrs.length).to eq 3

    attrFoo = div.attrs[0]
    expect(attrFoo).to be_a Rbexy::Nodes::XmlAttr
    expect(attrFoo.name).to eq "foo"
    expect(attrFoo.value).to be_a Rbexy::Nodes::Text
    expect(attrFoo.value.content).to eq ""

    attrBar = div.attrs[1]
    expect(attrBar).to be_a Rbexy::Nodes::XmlAttr
    expect(attrBar.name).to eq "bar"
    expect(attrBar.value).to be_a Rbexy::Nodes::Text
    expect(attrBar.value.content).to eq "baz"

    attrThing = div.attrs[2]
    expect(attrThing).to be_a Rbexy::Nodes::XmlAttr
    expect(attrThing.name).to eq "thing"
    expect(attrThing.value).to be_a Rbexy::Nodes::Expression
    expect(attrThing.value.content).to eq "exprValue"
  end

  it "parses splat attributes" do
    subject = Rbexy::Parser.new([
      [:OPEN_TAG_DEF],
      [:TAG_NAME, "div"],
      [:OPEN_ATTRS],
      [:OPEN_ATTR_SPLAT],
      [:OPEN_EXPRESSION],
      [:EXPRESSION, "{ attr1: 'val1', attr2: 'val2' }"],
      [:CLOSE_EXPRESSION],
      [:CLOSE_ATTR_SPLAT],
      [:CLOSE_ATTRS],
      [:CLOSE_TAG_DEF],
      [:OPEN_TAG_END],
      [:CLOSE_TAG_END]
    ])

    div = subject.parse.children.first
    expect(div).to be_a Rbexy::Nodes::XmlNode
    expect(div.attrs.length).to eq 1

    attrFoo = div.attrs[0]
    expect(attrFoo).to be_a Rbexy::Nodes::Expression
    expect(attrFoo.content).to eq "{ attr1: 'val1', attr2: 'val2' }"
  end

  it "finds no children for self-closing tags" do
    subject = Rbexy::Parser.new([
      [:OPEN_TAG_DEF],
      [:TAG_NAME, "input"],
      [:CLOSE_TAG_DEF],
      [:OPEN_TAG_END],
      [:CLOSE_TAG_END]
    ])

    input = subject.parse.children.first
    expect(input).to be_a Rbexy::Nodes::XmlNode
    expect(input.children.length).to eq 0
  end

  it "parses children" do
    subject = Rbexy::Parser.new([
      [:OPEN_TAG_DEF],
      [:TAG_NAME, "div"],
      [:CLOSE_TAG_DEF],
        [:OPEN_TAG_DEF],
        [:TAG_NAME, "h1"],
        [:CLOSE_TAG_DEF],

        [:OPEN_TAG_END],
        [:TAG_NAME, "h1"],
        [:CLOSE_TAG_END],

        [:OPEN_TAG_DEF],
        [:TAG_NAME, "p"],
        [:CLOSE_TAG_DEF],

          [:OPEN_TAG_DEF],
          [:TAG_NAME, "span"],
          [:CLOSE_TAG_DEF],
          [:OPEN_TAG_END],
          [:TAG_NAME, "span"],
          [:CLOSE_TAG_END],

        [:OPEN_TAG_END],
        [:TAG_NAME, "p"],
        [:CLOSE_TAG_END],

      [:OPEN_TAG_END],
      [:TAG_NAME, "div"],
      [:CLOSE_TAG_END]
    ])

    div = subject.parse.children.first
    expect(div).to be_a Rbexy::Nodes::XmlNode
    expect(div.name).to eq "div"
    expect(div.children.length).to eq 2

    h1 = div.children[0]
    expect(h1.name).to eq "h1"
    expect(h1.children.length).to eq 0

    p = div.children[1]
    expect(p.name).to eq "p"
    expect(p.children.length).to eq 1

    span = p.children[0]
    expect(span.name).to eq "span"
    expect(span.children.length).to eq 0
  end

  it "parses multiple things at the root" do
    subject = Rbexy::Parser.new([
      [:OPEN_TAG_DEF],
      [:TAG_NAME, "div"],
      [:CLOSE_TAG_DEF],
      [:OPEN_TAG_END],
      [:TAG_NAME, "div"],
      [:CLOSE_TAG_END],

      [:OPEN_TAG_DEF],
      [:TAG_NAME, "h1"],
      [:CLOSE_TAG_DEF],
      [:OPEN_TAG_END],
      [:TAG_NAME, "h1"],
      [:CLOSE_TAG_END]
    ])

    template = subject.parse

    div = template.children[0]
    expect(div.name).to eq "div"

    h1 = template.children[1]
    expect(h1.name).to eq "h1"
  end

  it "parses text within a tag into Rbexy::Nodes::Text" do
    subject = Rbexy::Parser.new([
      [:OPEN_TAG_DEF],
      [:TAG_NAME, "div"],
      [:CLOSE_TAG_DEF],
      [:TEXT, "Hello world"],
      [:OPEN_TAG_END],
      [:TAG_NAME, "div"],
      [:CLOSE_TAG_END]
    ])

    div = subject.parse.children.first
    text = div.children.first
    expect(text).to be_a Rbexy::Nodes::Text
    expect(text.content).to eq "Hello world"
  end

  it "parses expression within a tag into Rbexy::Nodes::Expression" do
    subject = Rbexy::Parser.new([
      [:OPEN_TAG_DEF],
      [:TAG_NAME, "div"],
      [:CLOSE_TAG_DEF],
      [:OPEN_EXPRESSION],
      [:EXPRESSION, "thing = 'foo'"],
      [:CLOSE_EXPRESSION],
      [:OPEN_TAG_END],
      [:TAG_NAME, "div"],
      [:CLOSE_TAG_END]
    ])

    div = subject.parse.children.first
    expr = div.children.first
    expect(expr).to be_a Rbexy::Nodes::Expression
    expect(expr.content).to eq "thing = 'foo'"
  end
end
