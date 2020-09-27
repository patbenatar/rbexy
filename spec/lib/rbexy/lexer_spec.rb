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
      [:EXPRESSION, "aVar"],
      [:OPEN_TAG_END],
      [:TAG_NAME, "div"],
      [:CLOSE_TAG_END]
    ]
  end

  it "tokenizes two expressions next to one another" do
    subject = Rbexy::Lexer.new("{aVar}{anotherVar}")
    expect(subject.tokenize).to eq [
      [:EXPRESSION, "aVar"],
      [:EXPRESSION, "anotherVar"],
    ]
  end

  it "tokenizes an expression along with text inside a tag" do
    subject = Rbexy::Lexer.new("<div>Hello {aVar}!</div>")
    expect(subject.tokenize).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_NAME, "div"],
      [:CLOSE_TAG_DEF],
      [:TEXT, "Hello "],
      [:EXPRESSION, "aVar"],
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
      [:EXPRESSION, 'thing = { hashKey: "value" }; moreCode'],
    ]
  end

  it "allows for expressions to have arbitrary brackets inside quoted strings" do
    subject = Rbexy::Lexer.new('{something "quoted {bracket}" \'{}\' "\'{\'" more}')
    expect(subject.tokenize).to eq [
      [:EXPRESSION, 'something "quoted {bracket}" \'{}\' "\'{\'" more'],
    ]
  end

  it "doesn't consider escaped quotes to end an expression quoted string" do
    subject = Rbexy::Lexer.new('{"he said \"hello {there}\" loudly"}')
    expect(subject.tokenize).to eq [
      [:EXPRESSION, '"he said \"hello {there}\" loudly"'],
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
      [:EXPRESSION, "aVar"],
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
      [:EXPRESSION, "exprValue"],
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
      [:EXPRESSION, "the_attrs"],
      [:CLOSE_ATTR_SPLAT],
      [:CLOSE_ATTRS],
      [:CLOSE_TAG_DEF]
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
      [:EXPRESSION, "dynamicId"],
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
