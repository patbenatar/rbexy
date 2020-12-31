RSpec.describe Rbexy::Parser do
  it "handles :TEXT" do
    subject = Rbexy::Parser.new([[:TEXT, "Hello world"]])
    result = subject.parse.children
    expect(result.first).to be_a Rbexy::Nodes::Text
    expect(result.first.content).to eq "Hello world"
  end

  it "parses declarations" do
    subject = Rbexy::Parser.new([
      [:DECLARATION, "<!DOCTYPE html>"]
    ])
    result = subject.parse.children
    expect(result.first).to be_a Rbexy::Nodes::Declaration
    expect(result.first.content).to eq "<!DOCTYPE html>"
  end

  it "parses expressions" do
    subject = Rbexy::Parser.new([
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "thing = 'bar'"],
      [:CLOSE_EXPRESSION],
    ])
    result = subject.parse.children
    expect(result.first).to be_a Rbexy::Nodes::ExpressionGroup
    group = result.first
    expect(group.members.first).to be_a Rbexy::Nodes::Expression
    expect(group.members.first.content).to eq "thing = 'bar'"
  end

  it "parses tags within expressions" do
    subject = Rbexy::Parser.new([
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "true && "],
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "h1", type: :html }],
      [:CLOSE_TAG_DEF],
      [:TEXT, "Is "],
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "'hello'.upcase"],
      [:CLOSE_EXPRESSION],
      [:OPEN_TAG_END],
      [:TAG_NAME, "h1"],
      [:CLOSE_TAG_END],
      [:EXPRESSION_BODY, ""],
      [:CLOSE_EXPRESSION],
    ])
    result = subject.parse.children

    expect(result.first).to be_a Rbexy::Nodes::ExpressionGroup
    group = result.first

    expect(group.members[0]).to be_a Rbexy::Nodes::Expression
    expect(group.members[0].content).to eq "true && "

    expect(group.members[1]).to be_a Rbexy::Nodes::HTMLElement
    expect(group.members[1].name).to eq "h1"
    expect(group.members[1].children[0]).to be_a Rbexy::Nodes::Text
    expect(group.members[1].children[0].content).to eq "Is "
    expect(group.members[1].children[1]).to be_a Rbexy::Nodes::ExpressionGroup
    expect(group.members[1].children[1].members[0].content).to eq "'hello'.upcase"

    expect(group.members[2]).to be_a Rbexy::Nodes::Expression
    expect(group.members[2].content).to eq ""
  end

  it "parses named tags" do
    subject = Rbexy::Parser.new([
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "div", type: :html }],
      [:CLOSE_TAG_DEF],
      [:OPEN_TAG_END],
      [:CLOSE_TAG_END]
    ])
    result = subject.parse.children
    expect(result.first).to be_a Rbexy::Nodes::HTMLElement
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
      [:TAG_DETAILS, { name: "div", type: :html }],
      [:CLOSE_TAG_DEF]
    ])
    expect { subject.parse }.to raise_error Rbexy::Parser::ParseError
  end

  it "parses tag attributes" do
    subject = Rbexy::Parser.new([
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "div", type: :html }],
      [:OPEN_ATTRS],
      [:ATTR_NAME, "foo"],
      [:ATTR_NAME, "bar"],
      [:OPEN_ATTR_VALUE],
      [:TEXT, "baz"],
      [:CLOSE_ATTR_VALUE],
      [:ATTR_NAME, "thing"],
      [:OPEN_ATTR_VALUE],
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "exprValue"],
      [:CLOSE_EXPRESSION],
      [:CLOSE_ATTR_VALUE],
      [:CLOSE_ATTRS],
      [:CLOSE_TAG_DEF],
      [:OPEN_TAG_END],
      [:CLOSE_TAG_END]
    ])

    div = subject.parse.children.first
    expect(div).to be_a Rbexy::Nodes::HTMLElement
    expect(div.members.length).to eq 3

    attrFoo = div.members[0]
    expect(attrFoo).to be_a Rbexy::Nodes::HTMLAttr
    expect(attrFoo.name).to eq "foo"
    expect(attrFoo.value).to be_a Rbexy::Nodes::Text
    expect(attrFoo.value.content).to eq ""

    attrBar = div.members[1]
    expect(attrBar).to be_a Rbexy::Nodes::HTMLAttr
    expect(attrBar.name).to eq "bar"
    expect(attrBar.value).to be_a Rbexy::Nodes::Text
    expect(attrBar.value.content).to eq "baz"

    attrThing = div.members[2]
    expect(attrThing).to be_a Rbexy::Nodes::HTMLAttr
    expect(attrThing.name).to eq "thing"
    expect(attrThing.value).to be_a Rbexy::Nodes::ExpressionGroup
    expect(attrThing.value.members.first.content).to eq "exprValue"
  end

  it "parses splat attributes" do
    subject = Rbexy::Parser.new([
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "div", type: :html }],
      [:OPEN_ATTRS],
      [:OPEN_ATTR_SPLAT],
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "{ attr1: 'val1', attr2: 'val2' }"],
      [:CLOSE_EXPRESSION],
      [:CLOSE_ATTR_SPLAT],
      [:CLOSE_ATTRS],
      [:CLOSE_TAG_DEF],
      [:OPEN_TAG_END],
      [:CLOSE_TAG_END]
    ])

    div = subject.parse.children.first
    expect(div).to be_a Rbexy::Nodes::HTMLElement
    expect(div.members.length).to eq 1

    attrFoo = div.members[0]
    expect(attrFoo).to be_a Rbexy::Nodes::ExpressionGroup
    expect(attrFoo.members.first.content).to eq "{ attr1: 'val1', attr2: 'val2' }"
  end

  it "finds no children for self-closing tags" do
    subject = Rbexy::Parser.new([
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "input", type: :html }],
      [:CLOSE_TAG_DEF],
      [:OPEN_TAG_END],
      [:CLOSE_TAG_END]
    ])

    input = subject.parse.children.first
    expect(input).to be_a Rbexy::Nodes::HTMLElement
    expect(input.children.length).to eq 0
  end

  it "parses children" do
    subject = Rbexy::Parser.new([
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "div", type: :html }],
      [:CLOSE_TAG_DEF],
        [:OPEN_TAG_DEF],
        [:TAG_DETAILS, { name: "h1", type: :html }],
        [:CLOSE_TAG_DEF],

        [:OPEN_TAG_END],
        [:TAG_NAME, "h1"],
        [:CLOSE_TAG_END],

        [:OPEN_TAG_DEF],
        [:TAG_DETAILS, { name: "p", type: :html }],
        [:CLOSE_TAG_DEF],

          [:OPEN_TAG_DEF],
          [:TAG_DETAILS, { name: "span", type: :html }],
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
    expect(div).to be_a Rbexy::Nodes::HTMLElement
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
      [:TAG_DETAILS, { name: "div", type: :html }],
      [:CLOSE_TAG_DEF],
      [:OPEN_TAG_END],
      [:TAG_NAME, "div"],
      [:CLOSE_TAG_END],

      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "h1", type: :html }],
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
      [:TAG_DETAILS, { name: "div", type: :html }],
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
      [:TAG_DETAILS, { name: "div", type: :html }],
      [:CLOSE_TAG_DEF],
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "thing = 'foo'"],
      [:CLOSE_EXPRESSION],
      [:OPEN_TAG_END],
      [:TAG_NAME, "div"],
      [:CLOSE_TAG_END]
    ])

    div = subject.parse.children.first
    expr = div.children.first
    expect(expr).to be_a Rbexy::Nodes::ExpressionGroup
    expect(expr.members.first.content).to eq "thing = 'foo'"
  end

  it "raises an error when encountering tag that opens but never closes" do
    subject = Rbexy::Parser.new([
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "div", type: :html }],
      [:CLOSE_TAG_DEF],
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "h1", type: :html }],
      [:CLOSE_TAG_DEF],
      [:TEXT, "Hello world"],
      [:OPEN_TAG_END],
      [:TAG_NAME, "h1"],
      [:CLOSE_TAG_END],
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "br", type: :html }],
      [:CLOSE_TAG_DEF],
      [:OPEN_TAG_END],
      [:TAG_NAME, "div"],
      [:CLOSE_TAG_END]
    ])

    expect { Timeout::timeout(1) { subject.parse } }
      .to raise_error(Rbexy::Parser::ParseError)
  end

  it "raises an error when encountering expression that opens but never closes" do
    subject = Rbexy::Parser.new([
      [:OPEN_EXPRESSION]
    ])

    expect { Timeout::timeout(1) { subject.parse } }
      .to raise_error(Rbexy::Parser::ParseError)
  end
end
