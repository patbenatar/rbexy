# A Ruby template language inspired by JSX

[![Build Status](https://travis-ci.org/patbenatar/rbexy.svg?branch=master)](https://travis-ci.org/patbenatar/rbexy)

* [Getting Started](#getting-started)
* [Template Syntax](#template-syntax)
* [Components](#components)
  * [`Rbexy::Component`](#rbexycomponent)
  * [Usage with any component library](#usage-with-any-component-library)
* [Fragment caching in Rails](#fragment-caching-in-rails)
* [Advanced](#advanced)
  * [Component resolution](#component-resolution)
  * [AST Transforms](#ast-transforms)
  * [Usage outside of Rails](#usage-outside-of-rails)

## Manifesto

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

Fire up `rails s`, navigate to your route, and you should see Rbexy in action!

## Template Syntax

You can use Ruby code within brackets:

```jsx
<p class={@dynamic_class}>
  Hello {"world".upcase}
</p>
```

You can splat a hash into attributes:

```jsx
<div {**{class: "myClass"}} {**@more_attrs}></div>
```

You can use HTML or component tags within expressions. e.g. to conditionalize a template:

```jsx
<div>
  {some_boolean && <h1>Welcome</h1>}
  {another_boolean ? <p>Option One</p> : <p>Option Two</p>}
</div>
```

Or in loops:

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

Pass a tag to a component as an attribute:

```jsx
<Hero title={<h1>Hello World</h1>}>
  Content here...
</Hero>
```

Or pass a lambda as an attribute, that when called returns a tag:

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

Start a line with `#` to leave a comment:

```jsx
# Private note to self that won't be rendered in the final HTML
```

## Components

You can use Ruby classes as components alongside standard HTML tags:

```jsx
<div>
  <PageHeader title="Welcome" />
  <PageBody>
    <p>To the world of custom components</p>
  </PageBody>
</div>
```

By default, Rbexy will resolve `PageHeader` to a Ruby class called `PageHeaderComponent` and render it with the view context, attributes, and its children: `PageHeaderComponent.new(self, title: "Welcome").render_in(self, &block)`. This behavior is customizable, see "Component resolution" below.

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

Your components and their templates run in the same context as traditional Rails views, so you have access to all of the view helpers you're used to as well as any custom helpers you've defined in `app/helpers/` or via `helper_method` in your controller.

#### Template-less components

If you'd prefer to render your components entirely from Ruby, you can do so by implementing `#call`:

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

#### Usage with ERB

We recommend using `Rbexy::Component` with the rbx template language, but if you prefer ERB... a component's template can be `.html.erb` and you  can render a component from ERB like so:

Rails 6.1:

```erb
<%= render PageHeaderComponent.new(self, title: "Welcome") do %>
  <p>Children...</p>
<% end >
```

Rails 6.0 or earlier:

```erb
<%= PageHeaderComponent.new(self, title: "Welcome").render_in(self) %>
```

### Usage with any component library

You can use the rbx template language with other component libraries like Github's view_component. You just need to tell Rbexy how to render the component:

```ruby
# config/initializers/rbexy.rb
Rbexy.configure do |config|
  config.component_rendering_templates = {
    children: "{capture{%{children}}}",
    component: "::%{component_class}.new(%{view_context},%{kwargs}).render_in%{children_block}"
  }
end
```

## Fragment caching in Rails

`.rbx` templates integrate with Rails fragment caching, automatically cachebusting when the template or its render dependencies change.

If you're using `Rbexy::Component`, you can further benefit from component cachebusting where the fragment cache will be busted if any dependent component's template _or_ class definition changes.

And you can use `<Rbexy.Cache>`, a convenient wrapper for the Rails fragment cache:

```rbx
<Rbexy.Cache key={...}>
  <p>Fragment here...</p>
  <MyButton />
</Rbexy.Cache>
```

## Advanced

### Component resolution

By default, Rbexy resolves component tags to Ruby classes named `#{tag}Component`, e.g.:

* `<PageHeader />` => `PageHeaderComponent`
* `<Admin.Button />` => `Admin::ButtonComponent`

You can customize this behavior by providing a custom resolver:

```ruby
# config/initializers/rbexy.rb
Rbexy.configure do |config|
  config.element_resolver = MyResolver.new
end
```

Where `MyResolver` implements the following API:

* `component?(name: string, template: Rbexy::Template) => Boolean`
* `component_class(name: string, template: Rbexy::Template) => T`

See `lib/rbexy/component_resolver.rb` for an example.

#### Auto-namespacing

Want to namespace your components but sick of typing `Admin.` in front of every component call? Rbexy's default `ComponentResolver` implementation has an option for that:

```ruby
# config/initializers/rbexy.rb
Rbexy.configure do |config|
  config.element_resolver.component_namespaces = {
    Rails.root.join("app", "views", "admin") => %w[Admin],
    Rails.root.join("app", "components", "admin") => %w[Admin]
  }
end
```

Now any calls to `<Button>` made from `.rbx` views within `app/views/admin/` or from component templates within `app/components/admin/` will first check for `Admin::ButtonComponent` before `ButtonComponent`.

### AST Transforms

You can hook into Rbexy's compilation process to mutate the abstract syntax tree. This is both useful and dangerous, so use with caution.

An example use case is automatically scoping CSS class names if you're using something like CSS Modules. Here's an oversimplified example of this:

```ruby
config.transforms.register(Rbexy::Nodes::HTMLAttr) do |node, context|
  if node.name == "class"
    class_list = node.value.split(" ")
    node.value.content = scope_names(class_list, scope: context.template.identifier)
  end
end
```

### Usage outside of Rails

Rbexy compiles your template into ruby code, which you can then execute in any context you like. Subclass `Rbexy::Runtime` to add methods and instance variables that you'd like to make available to your template.

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
