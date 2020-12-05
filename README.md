# A Ruby template language inspired by JSX

[![Build Status](https://travis-ci.org/patbenatar/rbexy.svg?branch=master)](https://travis-ci.org/patbenatar/rbexy)

Love JSX and component-based frontends, but sick of paying the costs of SPA development? Rbexy brings the elegance of JSX—operating on HTML elements and custom components with an interchangeable syntax—to the world of Rails server-rendered apps.

Combine this with CSS Modules in your Webpacker PostCSS pipeline and you'll have a first-class frontend development experience while maintaining the development efficiency of Rails.

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
class HeroComponent < Rbexy::Component # or use ViewComponent, or another component lib
  def setup(size:)
    @size = size
  end
end

class ButtonComponent < Rbexy::Component
  def setup(to:)
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

_From 1.0 onward, we only support Rails 6. If you're using Rails 5, use the 0.x releases._

In `config/application.rb`:

```ruby
require "rbexy/rails/engine"
```

_Not using Rails? See "Usage outside of Rails" below._

Create your first component at `app/components/hello_world_component.rb`:

```ruby
class HelloWorldComponent < Rbexy::Component
  def setup(name:)
    @name = name
  end
end
```

With a template `app/components/hello_world_component.rbx`:

```jsx
<div>
  <h1>Hello {@name}</h1>
  {content}
</div>
```

Add a controller, action, route, and `rbx` view like `app/views/hello_worlds/index.rbx`:

```jsx
<HelloWorld name="Nick">
  <p>Welcome to the world of component-based frontend development in Rails!</p>
</HelloWorld>
```

_Or you can render Rbexy components from ERB with `<%= HelloWorldComponent.new(self, name: "Nick").render %>`_

Fire up `rails s`, navigate to your route, and you should see Rbexy in action!

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

### Comments

Start a line with `#` to leave a comment:

```jsx
# Comments can be at the root
<div>
  # Or within tags
  # spanning multiple lines
  <h1>Hello world</h1>
</div>
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

Blocks:

```jsx
{link_to "/" do
  <span>Click me</span>
end}
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

_Note that when using tags inside blocks, the block must evaluate to a single root element. Rbexy behaves similar to JSX in this way. E.g.:_

```
# Do
-> { <span><i>Hello</i> World</span> }

# Don't
-> { <i>Hello</i> World }
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

You can use custom components alongside standard HTML tags:

```jsx
<div>
  <PageHeader title="Welcome" />
  <PageBody>
    <p>To the world of custom components</p>
  </PageBody>
</div>
```

### `Rbexy::Component`

We ship with a component superclass that integrates nicely with Rails' ActionView and the controller rendering context. You can use it to easily implement custom components in your Rails app:

```ruby
# app/components/page_header_component.rb
class PageHeaderComponent < Rbexy::Component
  def setup(title:)
    @title = title
  end
end
```

By default, we'll look for a template file in the same directory as the class and with a matching filename:

```jsx
// app/components/page_header_component.rbx
<h1>{@title}</h1>
```

You can call this component from another `.rbx` template file (`<PageHeader title="Hello" />`)—either one rendered by another component class or a Rails view file like `app/views/products/index.rbx`. Or you can call it from ERB (or any other template language) like `PageHeaderComponent.new(self, title: "Hello").render`.

Your components and their templates run in the same context as traditional Rails views, so you have access to all of the view helpers you're used to as well as any custom helpers you've defined in `app/helpers/`.

#### Template-less components

If you'd prefer to render your components entirely from Ruby, e.g. using Rails `tag` helpers, you can do so with `#call`:

```ruby
class PageHeaderComponent < Rbexy::Component
  def setup(title:)
    @title = title
  end

  def call
    tag.h1 @title
  end
end
```

#### Context

`Rbexy::Component` implements a similar notion to React's Context API, allowing you to pass data through the component tree without having to pass props down manually.

Given a template:

```jsx
<Form>
  <TextField field={:title} />
</Form>
```

The form component can use Rails `form_for` and then pass the `form` builder object down to any field components using context:

```ruby
class FormComponent < Rbexy::Component
  def setup(form_object:)
    @form_object = form_object
  end

  def call
    form_for @form_object do |form|
      create_context(:form, form)
      content
    end
  end
end

class TextFieldComponent < Rbexy::Component
  def setup(field:)
    @field = field
    @form = use_context(:form)
  end

  def call
    @form.text_field @field
  end
end
```

### `ViewComponent`

Using Github's view_component library? Rbexy ships with a provider that'll resolve your RBX tags like `<Button />` to their corresponding `ButtonComponent < ViewComponent::Base` components.

```ruby
require "rbexy/component_providers/view_component_provider"

Rbexy.configure do |config|
  config.component_provider = Rbexy::ComponentProviders::ViewComponentProvider.new
end
```

### Other types of components

You just need to tell rbexy how to resolve your custom component classes as it encounters them while evaluating your template by implementing a ComponentProvider:

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

Or in Rails you can customize the component provider just for a controller:

```ruby
class ThingsController < ApplicationController
  def rbexy_component_provider
    MyComponentProvider.new
  end
end
```

See `lib/rbexy/component_providers/` for example implementations.

## Usage outside of Rails

Rbexy compiles your template into ruby code, which you can then execute in any context you like, so long as a tag builder is available at `#rbexy_tag`. We provide a built-in runtime leveraging ActionView's `tag` helper that you can extend from or build your own:

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

Or auto-run tests with guard if you prefer:

```
docker-compose run rbexy guard
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/rbexy. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/rbexy/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Rbexy project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/rbexy/blob/master/CODE_OF_CONDUCT.md).
