require "active_support/core_ext/string/strip"

RSpec.describe Rbexy::Lexer do
  it "tokenizes text" do
    subject = Rbexy::Lexer.new("Hello world")
    expect(subject.tokenize).to eq [[:TEXT, "Hello world"]]
  end

  it "tokenizes xml tags" do
    subject = Rbexy::Lexer.new("<div></div>")
    expect(subject.tokenize).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_NAME, "div"],
      [:CLOSE_TAG_DEF],
      [:OPEN_TAG_END],
      [:TAG_NAME, "div"],
      [:CLOSE_TAG_END]
    ]
  end

  it "tokenizes self-closing xml tags" do
    variants = ["<input />", "<input/>"]
    variants.each do |code|
      subject = Rbexy::Lexer.new(code)
      expect(subject.tokenize).to eq [
        [:OPEN_TAG_DEF],
        [:TAG_NAME, "input"],
        [:CLOSE_TAG_DEF],
        [:OPEN_TAG_END],
        [:CLOSE_TAG_END]
      ]
    end
  end

  it "tokenizes html5 doctype declaration" do
    subject = Rbexy::Lexer.new("<!DOCTYPE html>")
    expect(subject.tokenize).to eq [
      [:DECLARATION, "<!DOCTYPE html>"]
    ]
  end

  it "tokenizes older html4 doctype declaration" do
    template = <<-RBX.strip_heredoc.strip
      <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
    RBX

    subject = Rbexy::Lexer.new(template)
    expect(subject.tokenize).to eq [
      [
        :DECLARATION,
        "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">"
      ]
    ]
  end

  it "tokenizes nested self-closing xml tags" do
    subject = Rbexy::Lexer.new("<div><br /></div>")
    expect(subject.tokenize).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_NAME, "div"],
      [:CLOSE_TAG_DEF],
      [:OPEN_TAG_DEF],
      [:TAG_NAME, "br"],
      [:CLOSE_TAG_DEF],
      [:OPEN_TAG_END],
      [:CLOSE_TAG_END],
      [:OPEN_TAG_END],
      [:TAG_NAME, "div"],
      [:CLOSE_TAG_END]
    ]
  end

  it "tokenizes self-closing xml tags with attributes" do
    variants = ['<input thing="value" />', '<input thing="value"/>']
    variants.each do |code|
      subject = Rbexy::Lexer.new(code)
      expect(subject.tokenize).to eq [
        [:OPEN_TAG_DEF],
        [:TAG_NAME, "input"],
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
    subject = Rbexy::Lexer.new("<div>Hello world</div>")
    expect(subject.tokenize).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_NAME, "div"],
      [:CLOSE_TAG_DEF],
      [:TEXT, "Hello world"],
      [:OPEN_TAG_END],
      [:TAG_NAME, "div"],
      [:CLOSE_TAG_END]
    ]
  end

  it "tokenizes an expression inside a tag" do
    subject = Rbexy::Lexer.new("<div>{aVar}</div>")
    expect(subject.tokenize).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_NAME, "div"],
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
    subject = Rbexy::Lexer.new("{aVar}{anotherVar}")
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
    subject = Rbexy::Lexer.new("<div>Hello {aVar}!</div>")
    expect(subject.tokenize).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_NAME, "div"],
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
    subject = Rbexy::Lexer.new('Hey \{thing\}')
    expect(subject.tokenize).to eq [
      [:TEXT, 'Hey \{thing\}']
    ]
  end

  it "allows for { ... } to exist within an expression (e.g. a Ruby hash)" do
    subject = Rbexy::Lexer.new('{thing = { hashKey: "value" }; moreCode}')
    expect(subject.tokenize).to eq [
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, 'thing = { hashKey: "value" }; moreCode'],
      [:CLOSE_EXPRESSION],
    ]
  end

  it "allows for expressions to have arbitrary brackets inside quoted strings" do
    subject = Rbexy::Lexer.new('{something "quoted {bracket}" \'{}\' "\'{\'" more}')
    expect(subject.tokenize).to eq [
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, 'something "quoted {bracket}" \'{}\' "\'{\'" more'],
      [:CLOSE_EXPRESSION],
    ]
  end

  it "doesn't consider escaped quotes to end an expression quoted string" do
    subject = Rbexy::Lexer.new('{"he said \"hello {there}\" loudly"}')
    expect(subject.tokenize).to eq [
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, '"he said \"hello {there}\" loudly"'],
      [:CLOSE_EXPRESSION],
    ]
  end

  it "tokenizes an expression that starts with a tag" do
    subject = Rbexy::Lexer.new("{<h1>Title</h1>}")
    expect(subject.tokenize).to eq [
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, ""],
      [:OPEN_TAG_DEF],
      [:TAG_NAME, "h1"],
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
    subject = Rbexy::Lexer.new("{true && <h1>Is true</h1>}")
    expect(subject.tokenize).to eq [
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "true && "],
      [:OPEN_TAG_DEF],
      [:TAG_NAME, "h1"],
      [:CLOSE_TAG_DEF],
      [:TEXT, "Is true"],
      [:OPEN_TAG_END],
      [:TAG_NAME, "h1"],
      [:CLOSE_TAG_END],
      [:EXPRESSION_BODY, ""],
      [:CLOSE_EXPRESSION],
    ]
  end

  it "does not specially tokenize boolean expressions that aren't followed by a tag" do
    subject = Rbexy::Lexer.new("{true && 'hey'}")
    expect(subject.tokenize).to eq [
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "true && 'hey'"],
      [:CLOSE_EXPRESSION],
    ]
  end

  it "allows for sub-expressions within a boolean expression tag" do
    subject = Rbexy::Lexer.new("{true && <h1>Is {'hello'.upcase}</h1>}")
    expect(subject.tokenize).to eq [
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "true && "],
      [:OPEN_TAG_DEF],
      [:TAG_NAME, "h1"],
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
    subject = Rbexy::Lexer.new("{true ? <h1>Yes</h1> : <h2>No</h2>}")
    expect(subject.tokenize).to eq [
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "true ? "],
      [:OPEN_TAG_DEF],
      [:TAG_NAME, "h1"],
      [:CLOSE_TAG_DEF],
      [:TEXT, "Yes"],
      [:OPEN_TAG_END],
      [:TAG_NAME, "h1"],
      [:CLOSE_TAG_END],
      [:EXPRESSION_BODY, " : "],
      [:OPEN_TAG_DEF],
      [:TAG_NAME, "h2"],
      [:CLOSE_TAG_DEF],
      [:TEXT, "No"],
      [:OPEN_TAG_END],
      [:TAG_NAME, "h2"],
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
    subject = Rbexy::Lexer.new(template)
    expect(subject.tokenize).to eq [
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "3.times do\n  "],
      [:OPEN_TAG_DEF],
      [:TAG_NAME, "p"],
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
    subject = Rbexy::Lexer.new(template)
    expect(subject.tokenize).to eq [
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "3.times do |n|\n  "],
      [:OPEN_TAG_DEF],
      [:TAG_NAME, "p"],
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
    subject = Rbexy::Lexer.new("{3.times { <p>Hello</p> }}")
    expect(subject.tokenize).to eq [
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "3.times { "],
      [:OPEN_TAG_DEF],
      [:TAG_NAME, "p"],
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
    subject = Rbexy::Lexer.new("{3.times { |n| <p>Hello</p> }}")
    expect(subject.tokenize).to eq [
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "3.times { |n| "],
      [:OPEN_TAG_DEF],
      [:TAG_NAME, "p"],
      [:CLOSE_TAG_DEF],
      [:TEXT, "Hello"],
      [:OPEN_TAG_END],
      [:TAG_NAME, "p"],
      [:CLOSE_TAG_END],
      [:EXPRESSION_BODY, " }"],
      [:CLOSE_EXPRESSION],
    ]
  end

  it "tokenizes value-less attributes" do
    subject = Rbexy::Lexer.new("<button disabled>")
    expect(subject.tokenize).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_NAME, "button"],
      [:OPEN_ATTRS],
      [:ATTR_NAME, "disabled"],
      [:CLOSE_ATTRS],
      [:CLOSE_TAG_DEF]
    ]
  end

  it "tokenizes attributes with double-quoted string values" do
    subject = Rbexy::Lexer.new('<button type="submit">')
    expect(subject.tokenize).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_NAME, "button"],
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
    subject = Rbexy::Lexer.new('<input value="Some \"value\"">')
    expect(subject.tokenize).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_NAME, "input"],
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
    subject = Rbexy::Lexer.new("<input value={aVar}>")
    expect(subject.tokenize).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_NAME, "input"],
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
    subject = Rbexy::Lexer.new('<div foo bar="baz" thing={exprValue}>')
    expect(subject.tokenize).to eq [
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
      [:EXPRESSION_BODY, "exprValue"],
      [:CLOSE_EXPRESSION],
      [:CLOSE_ATTR_VALUE],
      [:CLOSE_ATTRS],
      [:CLOSE_TAG_DEF]
    ]
  end

  it "tokenizes a kwarg splat attribute" do
    subject = Rbexy::Lexer.new('<div {**the_attrs}>')
    expect(subject.tokenize).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_NAME, "div"],
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

    subject = Rbexy::Lexer.new(code)
    expect(subject.tokenize).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_NAME, "div"],
      [:SILENT_NEWLINE],
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

    subject = Rbexy::Lexer.new(code)
    expect(subject.tokenize).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_NAME, "div"],
      [:OPEN_ATTRS],
      [:ATTR_NAME, "foo"],
      [:OPEN_ATTR_VALUE],
      [:TEXT, "bar"],
      [:CLOSE_ATTR_VALUE],
      [:SILENT_NEWLINE],
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

    subject = Rbexy::Lexer.new(code)
    expect(subject.tokenize).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_NAME, "input"],
      [:SILENT_NEWLINE],
      [:OPEN_ATTRS],
      [:ATTR_NAME, "foo"],
      [:OPEN_ATTR_VALUE],
      [:TEXT, "bar"],
      [:CLOSE_ATTR_VALUE],
      [:SILENT_NEWLINE],
      [:ATTR_NAME, "baz"],
      [:OPEN_ATTR_VALUE],
      [:TEXT, "bip"],
      [:CLOSE_ATTR_VALUE],
      [:SILENT_NEWLINE],
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

    subject = Rbexy::Lexer.new(code)
    expect(subject.tokenize).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_NAME, "div"],
      [:OPEN_ATTRS],
      [:ATTR_NAME, "foo"],
      [:OPEN_ATTR_VALUE],
      [:TEXT, "bar"],
      [:CLOSE_ATTR_VALUE],
      [:CLOSE_ATTRS],
      [:CLOSE_TAG_DEF],
      [:TEXT, "\n  "],
      [:OPEN_TAG_DEF],
      [:TAG_NAME, "h1"],
      [:CLOSE_TAG_DEF],
      [:TEXT, "Some heading"],
      [:OPEN_TAG_END],
      [:TAG_NAME, "h1"],
      [:CLOSE_TAG_END],
      [:TEXT, "\n  "],
      [:OPEN_TAG_DEF],
      [:TAG_NAME, "p"],
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
      [:TAG_NAME, "div"],
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
      [:TAG_NAME, "p"],
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
end
