require "active_support/core_ext/string/strip"

RSpec.describe Rbexy::Lexer do
  it "tokenizes text" do
    subject = Rbexy::Lexer.new(Rbexy::Template.new("Hello world"), Rbexy::ComponentResolver.new)
    expect(subject.tokenize).to eq [[:TEXT, "Hello world"]]
  end

  it "tokenizes html tags" do
    subject = Rbexy::Lexer.new(Rbexy::Template.new("<div></div>"), Rbexy::ComponentResolver.new)
    expect(subject.tokenize).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "div", type: :html }],
      [:CLOSE_TAG_DEF],
      [:OPEN_TAG_END],
      [:TAG_NAME, "div"],
      [:CLOSE_TAG_END]
    ]
  end

  it "tokenizes component tags" do
    redefine { ButtonComponent = Class.new }

    class Resolver
      def component?(name, template)
        name == "Button"
      end

      def component_class(name, template)
        name == "Button" ? ButtonComponent : nil
      end
    end

    subject = Rbexy::Lexer.new(Rbexy::Template.new("<Button></Button>"), Resolver.new)
    expect(subject.tokenize).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "Button", type: :component, component_class: ButtonComponent }],
      [:CLOSE_TAG_DEF],
      [:OPEN_TAG_END],
      [:TAG_NAME, "Button"],
      [:CLOSE_TAG_END]
    ]
  end

  it "tokenizes self-closing html tags" do
    variants = ["<input />", "<input/>"]
    variants.each do |code|
      subject = Rbexy::Lexer.new(Rbexy::Template.new(code), Rbexy::ComponentResolver.new)
      expect(subject.tokenize).to eq [
        [:OPEN_TAG_DEF],
        [:TAG_DETAILS, { name: "input", type: :html }],
        [:CLOSE_TAG_DEF],
        [:OPEN_TAG_END],
        [:CLOSE_TAG_END]
      ]
    end
  end

  it "tokenizes html5 doctype declaration" do
    subject = Rbexy::Lexer.new(Rbexy::Template.new("<!DOCTYPE html>"), Rbexy::ComponentResolver.new)
    expect(subject.tokenize).to eq [
      [:DECLARATION, "<!DOCTYPE html>"]
    ]
  end

  it "tokenizes older html4 doctype declaration" do
    template = <<-RBX.strip_heredoc.strip
      <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
    RBX

    subject = Rbexy::Lexer.new(Rbexy::Template.new(template), Rbexy::ComponentResolver.new)
    expect(subject.tokenize).to eq [
      [
        :DECLARATION,
        "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">"
      ]
    ]
  end

  it "tokenizes nested self-closing html tags" do
    subject = Rbexy::Lexer.new(Rbexy::Template.new("<div><br /></div>"), Rbexy::ComponentResolver.new)
    expect(subject.tokenize).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "div", type: :html }],
      [:CLOSE_TAG_DEF],
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "br", type: :html }],
      [:CLOSE_TAG_DEF],
      [:OPEN_TAG_END],
      [:CLOSE_TAG_END],
      [:OPEN_TAG_END],
      [:TAG_NAME, "div"],
      [:CLOSE_TAG_END]
    ]
  end

  it "tokenizes self-closing html tags with attributes" do
    variants = ['<input thing="value" />', '<input thing="value"/>']
    variants.each do |code|
      subject = Rbexy::Lexer.new(Rbexy::Template.new(code), Rbexy::ComponentResolver.new)
      expect(subject.tokenize).to eq [
        [:OPEN_TAG_DEF],
        [:TAG_DETAILS, { name: "input", type: :html }],
        [:OPEN_ATTRS],
        [:ATTR_NAME, "thing"],
        [:OPEN_ATTR_VALUE],
        [:TEXT, "value"],
        [:CLOSE_ATTR_VALUE],
        [:CLOSE_ATTRS],
        [:CLOSE_TAG_DEF],
        [:OPEN_TAG_END],
        [:CLOSE_TAG_END]
      ]
    end
  end

  it "tokenizes text inside a tag" do
    subject = Rbexy::Lexer.new(Rbexy::Template.new("<div>Hello world</div>"), Rbexy::ComponentResolver.new)
    expect(subject.tokenize).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "div", type: :html }],
      [:CLOSE_TAG_DEF],
      [:TEXT, "Hello world"],
      [:OPEN_TAG_END],
      [:TAG_NAME, "div"],
      [:CLOSE_TAG_END]
    ]
  end

  it "tokenizes an expression inside a tag" do
    subject = Rbexy::Lexer.new(Rbexy::Template.new("<div>{aVar}</div>"), Rbexy::ComponentResolver.new)
    expect(subject.tokenize).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "div", type: :html }],
      [:CLOSE_TAG_DEF],
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "aVar"],
      [:CLOSE_EXPRESSION],
      [:OPEN_TAG_END],
      [:TAG_NAME, "div"],
      [:CLOSE_TAG_END]
    ]
  end

  it "tokenizes two expressions next to one another" do
    subject = Rbexy::Lexer.new(Rbexy::Template.new("{aVar}{anotherVar}"), Rbexy::ComponentResolver.new)
    expect(subject.tokenize).to eq [
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "aVar"],
      [:CLOSE_EXPRESSION],
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "anotherVar"],
      [:CLOSE_EXPRESSION],
    ]
  end

  it "tokenizes an expression along with text inside a tag" do
    subject = Rbexy::Lexer.new(Rbexy::Template.new("<div>Hello {aVar}!</div>"), Rbexy::ComponentResolver.new)
    expect(subject.tokenize).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "div", type: :html }],
      [:CLOSE_TAG_DEF],
      [:TEXT, "Hello "],
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "aVar"],
      [:CLOSE_EXPRESSION],
      [:TEXT, "!"],
      [:OPEN_TAG_END],
      [:TAG_NAME, "div"],
      [:CLOSE_TAG_END]
    ]
  end

  it 'treats escaped \{ as text' do
    subject = Rbexy::Lexer.new(Rbexy::Template.new('Hey \{thing\}'), Rbexy::ComponentResolver.new)
    expect(subject.tokenize).to eq [
      [:TEXT, 'Hey \{thing\}']
    ]
  end

  it "allows for { ... } to exist within an expression (e.g. a Ruby hash)" do
    subject = Rbexy::Lexer.new(Rbexy::Template.new('{thing = { hashKey: "value" }; moreCode}'), Rbexy::ComponentResolver.new)
    expect(subject.tokenize).to eq [
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, 'thing = { hashKey: "value" }; moreCode'],
      [:CLOSE_EXPRESSION],
    ]
  end

  it "allows for expressions to have arbitrary brackets inside quoted strings" do
    subject = Rbexy::Lexer.new(Rbexy::Template.new('{something "quoted {bracket}" \'{}\' "\'{\'" more}'), Rbexy::ComponentResolver.new)
    expect(subject.tokenize).to eq [
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, 'something "quoted {bracket}" \'{}\' "\'{\'" more'],
      [:CLOSE_EXPRESSION],
    ]
  end

  it "doesn't consider escaped quotes to end an expression quoted string" do
    subject = Rbexy::Lexer.new(Rbexy::Template.new('{"he said \"hello {there}\" loudly"}'), Rbexy::ComponentResolver.new)
    expect(subject.tokenize).to eq [
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, '"he said \"hello {there}\" loudly"'],
      [:CLOSE_EXPRESSION],
    ]
  end

  it "tokenizes an expression that starts with a tag" do
    subject = Rbexy::Lexer.new(Rbexy::Template.new("{<h1>Title</h1>}"), Rbexy::ComponentResolver.new)
    expect(subject.tokenize).to eq [
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, ""],
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "h1", type: :html }],
      [:CLOSE_TAG_DEF],
      [:TEXT, "Title"],
      [:OPEN_TAG_END],
      [:TAG_NAME, "h1"],
      [:CLOSE_TAG_END],
      [:EXPRESSION_BODY, ""],
      [:CLOSE_EXPRESSION],
    ]
  end

  it "tokenizes tags within a boolean expression" do
    subject = Rbexy::Lexer.new(Rbexy::Template.new("{true && <h1>Is true</h1>}"), Rbexy::ComponentResolver.new)
    expect(subject.tokenize).to eq [
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "true && "],
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "h1", type: :html }],
      [:CLOSE_TAG_DEF],
      [:TEXT, "Is true"],
      [:OPEN_TAG_END],
      [:TAG_NAME, "h1"],
      [:CLOSE_TAG_END],
      [:EXPRESSION_BODY, ""],
      [:CLOSE_EXPRESSION],
    ]
  end

  it "tokenizes self-closing tags within a boolean expression" do
    template_string = <<-RBX.strip_heredoc.strip
      {true && <br />}
    RBX

    subject = Rbexy::Lexer.new(Rbexy::Template.new(template_string), Rbexy::ComponentResolver.new)
    expect(subject.tokenize).to eq [
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "true && "],
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "br", type: :html }],
      [:CLOSE_TAG_DEF],
      [:OPEN_TAG_END],
      [:CLOSE_TAG_END],
      [:EXPRESSION_BODY, ""],
      [:CLOSE_EXPRESSION]
    ]
  end

  it "tokenizes nested tags within a boolean expression" do
    template_string = <<-RBX.strip_heredoc.strip
      {true && <h1><span>Hey</span></h1>}
    RBX

    subject = Rbexy::Lexer.new(Rbexy::Template.new(template_string), Rbexy::ComponentResolver.new)
    expect(subject.tokenize).to eq [
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "true && "],
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "h1", type: :html }],
      [:CLOSE_TAG_DEF],
        [:OPEN_TAG_DEF],
        [:TAG_DETAILS, { name: "span", type: :html }],
        [:CLOSE_TAG_DEF],
        [:TEXT, "Hey"],
        [:OPEN_TAG_END],
        [:TAG_NAME, "span"],
        [:CLOSE_TAG_END],
      [:OPEN_TAG_END],
      [:TAG_NAME, "h1"],
      [:CLOSE_TAG_END],
      [:EXPRESSION_BODY, ""],
      [:CLOSE_EXPRESSION]
    ]
  end

  it "does not specially tokenize boolean expressions that aren't followed by a tag" do
    subject = Rbexy::Lexer.new(Rbexy::Template.new("{true && 'hey'}"), Rbexy::ComponentResolver.new)
    expect(subject.tokenize).to eq [
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "true && 'hey'"],
      [:CLOSE_EXPRESSION],
    ]
  end

  it "allows for sub-expressions within a boolean expression tag" do
    subject = Rbexy::Lexer.new(Rbexy::Template.new("{true && <h1>Is {'hello'.upcase}</h1>}"), Rbexy::ComponentResolver.new)
    expect(subject.tokenize).to eq [
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
    ]
  end

  it "tokenizes tags within a ternary expression" do
    subject = Rbexy::Lexer.new(Rbexy::Template.new("{true ? <h1>Yes</h1> : <h2>No</h2>}"), Rbexy::ComponentResolver.new)
    expect(subject.tokenize).to eq [
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "true ? "],
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "h1", type: :html }],
      [:CLOSE_TAG_DEF],
      [:TEXT, "Yes"],
      [:OPEN_TAG_END],
      [:TAG_NAME, "h1"],
      [:CLOSE_TAG_END],
      [:EXPRESSION_BODY, " : "],
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "h2", type: :html }],
      [:CLOSE_TAG_DEF],
      [:TEXT, "No"],
      [:OPEN_TAG_END],
      [:TAG_NAME, "h2"],
      [:CLOSE_TAG_END],
      [:EXPRESSION_BODY, ""],
      [:CLOSE_EXPRESSION],
    ]
  end

  it "tokenizes self-closing tags within a ternary expression" do
    subject = Rbexy::Lexer.new(Rbexy::Template.new("{true ? <br /> : <input />}"), Rbexy::ComponentResolver.new)
    expect(subject.tokenize).to eq [
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "true ? "],
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "br", type: :html }],
      [:CLOSE_TAG_DEF],
      [:OPEN_TAG_END],
      [:CLOSE_TAG_END],
      [:EXPRESSION_BODY, " : "],
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "input", type: :html }],
      [:CLOSE_TAG_DEF],
      [:OPEN_TAG_END],
      [:CLOSE_TAG_END],
      [:EXPRESSION_BODY, ""],
      [:CLOSE_EXPRESSION],
    ]
  end

  it "tokenizes tags within a boolean expression including an OR operator" do
    subject = Rbexy::Lexer.new(Rbexy::Template.new("{true || <p>Yes</p>}"), Rbexy::ComponentResolver.new)
    expect(subject.tokenize).to eq [
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "true || "],
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "p", type: :html }],
      [:CLOSE_TAG_DEF],
      [:TEXT, "Yes"],
      [:OPEN_TAG_END],
      [:TAG_NAME, "p"],
      [:CLOSE_TAG_END],
      [:EXPRESSION_BODY, ""],
      [:CLOSE_EXPRESSION],
    ]
  end

  it "tokenizes tags within a do..end block" do
    template = <<-RBX.strip
{3.times do
  <p>Hello</p>
end}
RBX
    subject = Rbexy::Lexer.new(Rbexy::Template.new(template), Rbexy::ComponentResolver.new)
    expect(subject.tokenize).to eq [
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "3.times do\n  "],
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "p", type: :html }],
      [:CLOSE_TAG_DEF],
      [:TEXT, "Hello"],
      [:OPEN_TAG_END],
      [:TAG_NAME, "p"],
      [:CLOSE_TAG_END],
      [:EXPRESSION_BODY, "\nend"],
      [:CLOSE_EXPRESSION],
    ]
  end

  it "tokenizes tags within a do |var|..end block" do
    template = <<-RBX.strip
{3.times do |n|
  <p>Hello</p>
end}
RBX
    subject = Rbexy::Lexer.new(Rbexy::Template.new(template), Rbexy::ComponentResolver.new)
    expect(subject.tokenize).to eq [
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "3.times do |n|\n  "],
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "p", type: :html }],
      [:CLOSE_TAG_DEF],
      [:TEXT, "Hello"],
      [:OPEN_TAG_END],
      [:TAG_NAME, "p"],
      [:CLOSE_TAG_END],
      [:EXPRESSION_BODY, "\nend"],
      [:CLOSE_EXPRESSION],
    ]
  end

  it "tokenizes tags within a {..} block" do
    subject = Rbexy::Lexer.new(Rbexy::Template.new("{3.times { <p>Hello</p> }}"), Rbexy::ComponentResolver.new)
    expect(subject.tokenize).to eq [
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "3.times { "],
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "p", type: :html }],
      [:CLOSE_TAG_DEF],
      [:TEXT, "Hello"],
      [:OPEN_TAG_END],
      [:TAG_NAME, "p"],
      [:CLOSE_TAG_END],
      [:EXPRESSION_BODY, " }"],
      [:CLOSE_EXPRESSION],
    ]
  end

  it "tokenizes tags within a {|var|..} block" do
    subject = Rbexy::Lexer.new(Rbexy::Template.new("{3.times { |n| <p>Hello</p> }}"), Rbexy::ComponentResolver.new)
    expect(subject.tokenize).to eq [
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "3.times { |n| "],
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "p", type: :html }],
      [:CLOSE_TAG_DEF],
      [:TEXT, "Hello"],
      [:OPEN_TAG_END],
      [:TAG_NAME, "p"],
      [:CLOSE_TAG_END],
      [:EXPRESSION_BODY, " }"],
      [:CLOSE_EXPRESSION],
    ]
  end

  it "doesn't try to parse tags within %q(...) string notation" do
    template_string = <<-RBX.strip_heredoc.strip
      <div attr={%q(
        <p>something</p>
      )} />
    RBX
    subject = Rbexy::Lexer.new(Rbexy::Template.new(template_string), Rbexy::ComponentResolver.new)
    expect(subject.tokenize).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "div", type: :html }],
      [:OPEN_ATTRS],
      [:ATTR_NAME, "attr"],
      [:OPEN_ATTR_VALUE],
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "%q(\n  <p>something</p>\n)"],
      [:CLOSE_EXPRESSION],
      [:CLOSE_ATTR_VALUE],
      [:CLOSE_ATTRS],
      [:CLOSE_TAG_DEF],
      [:OPEN_TAG_END],
      [:CLOSE_TAG_END]
    ]
  end

  it "tokenizes value-less attributes" do
    subject = Rbexy::Lexer.new(Rbexy::Template.new("<button disabled>"), Rbexy::ComponentResolver.new)
    expect(subject.tokenize).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "button", type: :html }],
      [:OPEN_ATTRS],
      [:ATTR_NAME, "disabled"],
      [:CLOSE_ATTRS],
      [:CLOSE_TAG_DEF]
    ]
  end

  it "tokenizes attributes with double-quoted string values" do
    subject = Rbexy::Lexer.new(Rbexy::Template.new('<button type="submit">'), Rbexy::ComponentResolver.new)
    expect(subject.tokenize).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "button", type: :html }],
      [:OPEN_ATTRS],
      [:ATTR_NAME, "type"],
      [:OPEN_ATTR_VALUE],
      [:TEXT, "submit"],
      [:CLOSE_ATTR_VALUE],
      [:CLOSE_ATTRS],
      [:CLOSE_TAG_DEF]
    ]
  end

  it "treats escaped \\\" as part of the attribute value" do
    subject = Rbexy::Lexer.new(Rbexy::Template.new('<input value="Some \"value\"">'), Rbexy::ComponentResolver.new)
    expect(subject.tokenize).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "input", type: :html }],
      [:OPEN_ATTRS],
      [:ATTR_NAME, "value"],
      [:OPEN_ATTR_VALUE],
      [:TEXT, 'Some \"value\"'],
      [:CLOSE_ATTR_VALUE],
      [:CLOSE_ATTRS],
      [:CLOSE_TAG_DEF]
    ]
  end

  it "tokenizes attributes with expression values" do
    subject = Rbexy::Lexer.new(Rbexy::Template.new("<input value={aVar}>"), Rbexy::ComponentResolver.new)
    expect(subject.tokenize).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "input", type: :html }],
      [:OPEN_ATTRS],
      [:ATTR_NAME, "value"],
      [:OPEN_ATTR_VALUE],
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "aVar"],
      [:CLOSE_EXPRESSION],
      [:CLOSE_ATTR_VALUE],
      [:CLOSE_ATTRS],
      [:CLOSE_TAG_DEF]
    ]
  end

  it "tokenizes a combination of types of attributes" do
    subject = Rbexy::Lexer.new(Rbexy::Template.new('<div foo bar="baz" thing={exprValue}>'), Rbexy::ComponentResolver.new)
    expect(subject.tokenize).to eq [
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
      [:CLOSE_TAG_DEF]
    ]
  end

  it "tokenizes a kwarg splat attribute" do
    subject = Rbexy::Lexer.new(Rbexy::Template.new('<div {**the_attrs}>'), Rbexy::ComponentResolver.new)
    expect(subject.tokenize).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "div", type: :html }],
      [:OPEN_ATTRS],
      [:OPEN_ATTR_SPLAT],
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "the_attrs"],
      [:CLOSE_EXPRESSION],
      [:CLOSE_ATTR_SPLAT],
      [:CLOSE_ATTRS],
      [:CLOSE_TAG_DEF]
    ]
  end

  it "adds a silent newline between tag name and attributes that come on the next line (for source mapping)" do
    code = <<-CODE.strip_heredoc.strip
      <div
        foo="bar">
      </div>
    CODE

    subject = Rbexy::Lexer.new(Rbexy::Template.new(code), Rbexy::ComponentResolver.new)
    expect(subject.tokenize).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "div", type: :html }],
      [:NEWLINE],
      [:OPEN_ATTRS],
      [:ATTR_NAME, "foo"],
      [:OPEN_ATTR_VALUE],
      [:TEXT, "bar"],
      [:CLOSE_ATTR_VALUE],
      [:CLOSE_ATTRS],
      [:CLOSE_TAG_DEF],
      [:TEXT, "\n"],
      [:OPEN_TAG_END],
      [:TAG_NAME, "div"],
      [:CLOSE_TAG_END],
    ]
  end

  it "allows attributes to span multiple lines" do
    code = <<-CODE.strip_heredoc.strip
      <div foo="bar"
           baz="bip">
      </div>
    CODE

    subject = Rbexy::Lexer.new(Rbexy::Template.new(code), Rbexy::ComponentResolver.new)
    expect(subject.tokenize).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "div", type: :html }],
      [:OPEN_ATTRS],
      [:ATTR_NAME, "foo"],
      [:OPEN_ATTR_VALUE],
      [:TEXT, "bar"],
      [:CLOSE_ATTR_VALUE],
      [:NEWLINE],
      [:ATTR_NAME, "baz"],
      [:OPEN_ATTR_VALUE],
      [:TEXT, "bip"],
      [:CLOSE_ATTR_VALUE],
      [:CLOSE_ATTRS],
      [:CLOSE_TAG_DEF],
      [:TEXT, "\n"],
      [:OPEN_TAG_END],
      [:TAG_NAME, "div"],
      [:CLOSE_TAG_END],
    ]
  end

  it "allows attributes to be on the next line after the tag name" do
    code = <<-CODE.strip_heredoc.strip
      <input
        foo="bar"
        baz="bip"
      />
    CODE

    subject = Rbexy::Lexer.new(Rbexy::Template.new(code), Rbexy::ComponentResolver.new)
    expect(subject.tokenize).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "input", type: :html }],
      [:NEWLINE],
      [:OPEN_ATTRS],
      [:ATTR_NAME, "foo"],
      [:OPEN_ATTR_VALUE],
      [:TEXT, "bar"],
      [:CLOSE_ATTR_VALUE],
      [:NEWLINE],
      [:ATTR_NAME, "baz"],
      [:OPEN_ATTR_VALUE],
      [:TEXT, "bip"],
      [:CLOSE_ATTR_VALUE],
      [:NEWLINE],
      [:CLOSE_ATTRS],
      [:CLOSE_TAG_DEF],
      [:OPEN_TAG_END],
      [:CLOSE_TAG_END],
    ]
  end

  it "tokenizes attributes with colon in the name" do
    code = <<-CODE.strip_heredoc.strip
      <svg version="1.1" xmlns:xlink="http://www.w3.org/1999/xlink" />
    CODE

    subject = Rbexy::Lexer.new(Rbexy::Template.new(code), Rbexy::ComponentResolver.new)
    expect(subject.tokenize).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "svg", type: :html }],
      [:OPEN_ATTRS],
      [:ATTR_NAME, "version"],
      [:OPEN_ATTR_VALUE],
      [:TEXT, "1.1"],
      [:CLOSE_ATTR_VALUE],
      [:ATTR_NAME, "xmlns:xlink"],
      [:OPEN_ATTR_VALUE],
      [:TEXT, "http://www.w3.org/1999/xlink"],
      [:CLOSE_ATTR_VALUE],
      [:CLOSE_ATTRS],
      [:CLOSE_TAG_DEF],
      [:OPEN_TAG_END],
      [:CLOSE_TAG_END],
    ]
  end

  it "tokenizes some big nested markup with attributes" do
    code = <<-CODE.strip_heredoc
      <div foo="bar">
        <h1>Some heading</h1>
        <p class="someClass">A paragraph</p>
        <div id={dynamicId} class="divClass">
          <p>More text</p>
        </div>
      </div>
    CODE

    subject = Rbexy::Lexer.new(Rbexy::Template.new(code), Rbexy::ComponentResolver.new)
    expect(subject.tokenize).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "div", type: :html }],
      [:OPEN_ATTRS],
      [:ATTR_NAME, "foo"],
      [:OPEN_ATTR_VALUE],
      [:TEXT, "bar"],
      [:CLOSE_ATTR_VALUE],
      [:CLOSE_ATTRS],
      [:CLOSE_TAG_DEF],
      [:TEXT, "\n  "],
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "h1", type: :html }],
      [:CLOSE_TAG_DEF],
      [:TEXT, "Some heading"],
      [:OPEN_TAG_END],
      [:TAG_NAME, "h1"],
      [:CLOSE_TAG_END],
      [:TEXT, "\n  "],
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "p", type: :html }],
      [:OPEN_ATTRS],
      [:ATTR_NAME, "class"],
      [:OPEN_ATTR_VALUE],
      [:TEXT, "someClass"],
      [:CLOSE_ATTR_VALUE],
      [:CLOSE_ATTRS],
      [:CLOSE_TAG_DEF],
      [:TEXT, "A paragraph"],
      [:OPEN_TAG_END],
      [:TAG_NAME, "p"],
      [:CLOSE_TAG_END],
      [:TEXT, "\n  "],
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "div", type: :html }],
      [:OPEN_ATTRS],
      [:ATTR_NAME, "id"],
      [:OPEN_ATTR_VALUE],
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "dynamicId"],
      [:CLOSE_EXPRESSION],
      [:CLOSE_ATTR_VALUE],
      [:ATTR_NAME, "class"],
      [:OPEN_ATTR_VALUE],
      [:TEXT, "divClass"],
      [:CLOSE_ATTR_VALUE],
      [:CLOSE_ATTRS],
      [:CLOSE_TAG_DEF],
      [:TEXT, "\n    "],
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "p", type: :html }],
      [:CLOSE_TAG_DEF],
      [:TEXT, "More text"],
      [:OPEN_TAG_END],
      [:TAG_NAME, "p"],
      [:CLOSE_TAG_END],
      [:TEXT, "\n  "],
      [:OPEN_TAG_END],
      [:TAG_NAME, "div"],
      [:CLOSE_TAG_END],
      [:TEXT, "\n"],
      [:OPEN_TAG_END],
      [:TAG_NAME, "div"],
      [:CLOSE_TAG_END],
      [:TEXT, "\n"]
    ]
  end

  context "comments" do
    it "tokenizes lines starting with # as NEWLINE" do
      template_string = <<-RBX.strip_heredoc.strip
        Hello
        # some comment
        world
      RBX

      subject = Rbexy::Lexer.new(Rbexy::Template.new(template_string), Rbexy::ComponentResolver.new)
      expect(subject.tokenize).to eq [
        [:TEXT, "Hello\n"],
        [:NEWLINE],
        [:TEXT, "world"],
      ]
    end

    it "does not treat pound signs in the middle of a line as a comment" do
      template_string = <<-RBX.strip_heredoc.strip
        Hello # pound sign
      RBX

      subject = Rbexy::Lexer.new(Rbexy::Template.new(template_string), Rbexy::ComponentResolver.new)
      expect(subject.tokenize).to eq [
        [:TEXT, "Hello # pound sign\n"]
      ]
    end

    it "tokenizes the first line if starting with # as NEWLINE" do
      template_string = <<-RBX.strip_heredoc.strip
        # some comment
        Hello world
      RBX

      subject = Rbexy::Lexer.new(Rbexy::Template.new(template_string), Rbexy::ComponentResolver.new)
      expect(subject.tokenize).to eq [
        [:NEWLINE],
        [:TEXT, "Hello world"],
      ]
    end

    it "tokenizes the last line if starting with # as NEWLINE" do
      template_string = <<-RBX.strip_heredoc.strip
      Hello world
      # some comment
      RBX

      subject = Rbexy::Lexer.new(Rbexy::Template.new(template_string), Rbexy::ComponentResolver.new)
      expect(subject.tokenize).to eq [
        [:TEXT, "Hello world\n"],
        [:NEWLINE],
      ]
    end

    it "trims trailing whitespace from text before a comment line" do
      template_string = <<-RBX.strip_heredoc.strip
        Hello world
          # some indented comment
        Another text
      RBX

      subject = Rbexy::Lexer.new(Rbexy::Template.new(template_string), Rbexy::ComponentResolver.new)
      expect(subject.tokenize).to eq [
        [:TEXT, "Hello world\n"],
        [:NEWLINE],
        [:TEXT, "Another text"]
      ]
    end

    it "allows comments as children of tags" do
      template_string = <<-RBX.strip_heredoc.strip
        <div>
          # some comment
        </div>
      RBX

      subject = Rbexy::Lexer.new(Rbexy::Template.new(template_string), Rbexy::ComponentResolver.new)
      expect(subject.tokenize).to eq [
        [:OPEN_TAG_DEF],
        [:TAG_DETAILS, { name: "div", type: :html }],
        [:CLOSE_TAG_DEF],
        [:TEXT, "\n"],
        [:NEWLINE],
        [:OPEN_TAG_END],
        [:TAG_NAME, "div"],
        [:CLOSE_TAG_END],
      ]
    end

    it "treats an escaped \\# as TEXT" do
      subject = Rbexy::Lexer.new(Rbexy::Template.new('\# not a comment'), Rbexy::ComponentResolver.new)
      expect(subject.tokenize).to eq [
        [:TEXT, '\# not a comment']
      ]
    end
  end
end
