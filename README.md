# A Ruby template language inspired by JSX

[![Build Status](https://travis-ci.org/patbenatar/rbexy.svg?branch=master)](https://travis-ci.org/patbenatar/rbexy)

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

## Getting Started (with Rails)

Add it to your Gemfile and `bundle install`:

```ruby
gem "rbexy"
```

In `config/application.rb`:

```ruby
require "rbexy/rails/engine"
```

Add a `config/initializers/rbexy.rb` and register your ComponentProvider (see "Custom components" below for more info):

```ruby
Rbexy.configure do |config|
  config.component_provider = MyComponentProvider.new
end
```

Using Github's view_component library? Rbexy ships with a provider for that:

```ruby
require "rbexy/component_providers/view_component_provider"

Rbexy.configure do |config|
  config.component_provider = Rbexy::ComponentProviders::ViewComponentProvider.new
end
```

_For usage outside of Rails, see "Usage outside of Rails" below._

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

#### Tags within expressions

To conditionalize your template:

```jsx
<div>
  {some_boolean && <h1>Welcome</h1>}
  {another_boolean ? <p>Option One</p> : <p>Option Two</p>}
</div>
```

Loops:

```jsx
<ul>
  {[1, 2, 3].map { |n| <li>{n}</li> }}
</ul>
```

As an attribute:

```jsx
<Hero title={<h1>Hello World</h1>}>
  Content here...
</Hero>
```

Pass a lambda to a prop, that when called returns a tag:

```jsx
<Hero title={-> { <h1>Hello World</h1> }}>
  Content here...
</Hero>
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

## Custom components

You can use custom components alongside standard HTML tags. You just need to tell rbexy how to resolve your custom component classes as it encounters them while evaluating your template by implementing a ComponentProvider:

```ruby
class MyComponentProvider
  def match?(name)
    # Return true if the given tag name matches one of your custom components
  end

  def render(context, name, **attrs, &block)
    # Instantiate and render your custom component for the given name, using
    # the render context as needed (e.g. ActionView in Rails)
  end
end

# Register your component provider with Rbexy
Rbexy.configure do |config|
  config.component_provider = MyComponentProvider.new
end
```

See `lib/rbexy/component_providers/` for example implementations.

Using Github's view_component library? Rbexy ships with a provider for that:

```ruby
require "rbexy/component_providers/view_component_provider"

Rbexy.configure do |config|
  config.component_provider = Rbexy::ComponentProviders::ViewComponentProvider.new
end
```

## Context

Rbexy provides a "context" similar to React, allowing for passing data down the component tree without having to manually pass it as props.

With a template like:

```jsx
<Form>
  <TextField />
</Form>
```

You can use context to pass data from the form to its fields:

```ruby
class FormComponent
  def render(context)
    context.create_context(:form, MyFormObject.new)
    # ...
  end
end

class TextFieldComponent
  def render(context)
    form_object = context.use_context(:form)
    # ...
  end
end
```

Or if you're using view_component, `create_context` and `use_context` will be automatically available to you anywhere in your component:

```ruby
class FormComponent < ViewComponent::Base
  def initialize
    create_context(:form, MyFormObject.new)
  end
end
```

## Usage outside of Rails

Rbexy compiles your template into ruby code, which you can then execute in any context you like, so long as a tag builder is available at `#rbexy_tag`. We provide a built-in runtime leveraging ActionView's helpers that you can extend from or build your own:

Subclass to add methods and instance variables that you'd like to make available to your template.

```ruby
class MyRuntime < Rbexy::Runtime
  def initialize
    super
    @an_ivar = "Ivar value"
  end

  def a_method
    "Method value"
  end
end

Rbexy.evaluate("<p class={a_method}>{@an_ivar}</p>", MyRuntime.new)
```

If you're using custom components, inject a ComponentProvider (see "Custom components" for an example implementation):

```ruby
class MyRuntime < Rbexy::Runtime
  def initialize(component_provider)
    super(component_provider)
    @ivar_val = "ivar value"
  end

  def splat_attrs
    {
      key1: "val1",
      key2: "val2"
    }
  end
end

Rbexy.evaluate(
  "<Forms.TextField /><Button prop1=\"val1\" prop2={true && \"val2\">Submit</Button>",
  MyRuntime.new(MyComponentProvider.new)
)
```

Or implement your own runtime, so long as it conforms to the API:

* `#rbexy_tag` that returns a tag builder conforming to the API of `ActionView::Helpers::TagHelpers::TagBuilder`
* `#evaluate(code)` that evals the given string of ruby code

## Development

```
docker-compose build
docker-compose run rbexy rspec
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/rbexy. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/rbexy/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Rbexy project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/rbexy/blob/master/CODE_OF_CONDUCT.md).
