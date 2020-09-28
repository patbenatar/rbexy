# A Ruby template language inspired by JSX

Love JSX and component-based frontends, but sick of paying the costs of SPA development? Rbexy brings the elegance of JSX—operating on HTML elements and custom components with an interchangeable syntax—to the world of Rails server-rendered apps.

Combine this with a component library like Github's view_component and build CSS Modules into your Webpacker PostCSS pipeline—you'll have a first-class frontend development experience while maintaining the development efficiency of Rails.

_But what about Javascript and client-side behavior?_ You probably don't need as much of it as you think you do. See how far you can get with layering RailsUJS, vanilla JS, Turbolinks, and/or StimulusJS onto your server-rendered components. I think you'll be pleasantly surprised with the modern UX you're able to build while writing and maintaining less code.

## Example

Use your custom Ruby class components from `.rbx` templates just like you would React components in JSX:

```jsx
<body>
  <Hero size="fullscreen" {**splat_some_attributes}>
    <h1>Hello {@name}</h1>
    <p>Welcome to rbexy, marrying the nice parts of React templating with the development efficiency of Rails server-rendered apps.</p>
    <Button to={about_path}>Learn more</Button>
  </Hero>
</body>
```

after defining them in Ruby:

```ruby
class HeroComponent < ViewComponent::Base
  def initialize(size:)
    @size = size
  end
end

class ButtonComponent < ViewComponent::Base
  def initialize(to:)
    @to = to
  end
end
```

with their accompying template files (also can be `.rbx`!), scoped scss files, JS and other assets (not shown).

## Template Syntax

### Text

You can put arbitrary strings anywhere.

At the root:

```jsx
Hello world
```

Inside tags:

```jsx
<p>Hello world</p>
```

As attributes:

```jsx
<div class="myClass"></div>
```

### Expressions

You can put ruby code anywhere that you would put text, just wrap it in `{ ... }`

At the root:

```jsx
{"hello world".upcase}
```

Inside a sentence:

```jsx
Hello {"world".upcase}
```

Inside tags:

```jsx
<p>{"hello world".upcase}</p>
```

As attributes:

```jsx
<p class={@dynamic_class}>Hello world</p>
```

#### Execution Context

You can control the context in which your ruby expressions are evaluated by the rbexy compiler, allowing you to make ivars, methods, etc available to your template expressions:

```ruby
class CompileContext
  def initialize
    @an_ivar = "Ivar value"
  end

  def a_method
    "Method value"
  end
end

Rbexy.compile(
  "<p class={a_method}>{@an_ivar}</p>",
  Rbexy::HtmlCompiler.new(CompileContext.new)
)
```

### Tags

You can put standard HTML tags anywhere.

At the root:

```jsx
<h1>Hello world</h1>
```

As children:

```jsx
<div>
  <h1>Hello world</h1>
</div>
```

As siblings with other tags:

```jsx
<div>
  <h1>Hello world</h1>
  <p>Welcome to rbexy</p>
</div>
```

As siblings with text and expressions:

```jsx
<h1>Hello world</h1>
{an_expression}
Some arbitrary text
```

Self-closing tags:

```jsx
<input type="text" />
```

#### Attributes

Text and expressions can be provided as attributes:

```jsx
<div class="myClass" id={dynamic_id}></div>
```

Value-less attributes are allowed:

```jsx
<input type="submit" disabled>
```

You can splat a hash into attributes:

```jsx
<div {**{ class: "myClass" }} {**@more_attrs}></div>
```

#### Custom components

Use the `Rbexy::ComponentCompiler` to add support for custom components (like those implemented with view_component or other ruby component libraries). You just need to tell rbexy how to render your custom components as it encounters them during the compile.

```ruby
module Components
  class ButtonComponent < ViewComponent::Base
    def initialize(**attrs)
    end

    def render
      # Render it yourself, call one of Rails view helpers (link_to,
      # content_tag, etc), or use a template file. Be sure to render children
      # by yielding to the given block.
      "<button class=\"myCustomButton\">#{yield.join("")}</button>"
    end
  end

  module Forms
    class TextFieldComponent < ViewComponent::Base
      def initialize(**attrs)
      end

      def render
        "<input type=\"text\" />"
      end
    end
  end
end

class ComponentProvider
  def match?(name)
    find(name) != nil
  end

  def render(name, attrs, &block)
    find(name).new(**attrs).render(&block)
  end

  def find(name)
    ActiveSupport::Inflector.constantize(name.gsub(".", "::"))
  rescue NameError => e
    nil
  end
end

Rbexy.compile(
  "<Forms.TextField /><Button>Submit</Button>",
  Rbexy::ComponentCompiler.new(CompileContext.new, ComponentProvider.new)
)
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem "rbexy"
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install rbexy

## Development

```
docker-compose build
docker-compose run rbexy spec
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/rbexy. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/rbexy/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Rbexy project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/rbexy/blob/master/CODE_OF_CONDUCT.md).
