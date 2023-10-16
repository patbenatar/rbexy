require_relative 'lib/rbexy/version'

Gem::Specification.new do |spec|
  spec.name          = "rbexy"
  spec.version       = Rbexy::VERSION
  spec.authors       = ["Nick Giancola"]
  spec.email         = ["patbenatar@gmail.com"]

  spec.summary       = "A Ruby template language inspired by JSX"
  spec.homepage      = "https://github.com/patbenatar/rbexy"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.0")

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/patbenatar/rbexy"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 6", "< 7.2"
  spec.add_dependency "actionview", ">= 6", "< 7.2"

  spec.add_development_dependency "appraisal", "~> 2.2"
  spec.add_development_dependency "rails", ">= 6", "< 7.2"
  spec.add_development_dependency "sprockets-rails", ">= 2", "< 4"
  spec.add_development_dependency "rspec", "~> 3.9"
  spec.add_development_dependency "guard-rspec", "~> 4.7", ">= 4.7.3"
  spec.add_development_dependency "rspec-rails", "~> 4.0", ">= 4.0.1"
  spec.add_development_dependency "rspec-html-matchers", "~> 0.9.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "puma"
  spec.add_development_dependency "memory_profiler", "~> 0.9.14"
end
