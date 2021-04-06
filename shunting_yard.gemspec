require_relative 'lib/shunting_yard/version'

Gem::Specification.new do |spec|
  spec.name          = "shunting_yard"
  spec.version       = ShuntingYard::VERSION
  spec.authors       = ["Artem Rashev"]
  spec.email         = ["artem.rashev@protonmail.com"]

  spec.summary       = "ShuntingYard algorithm implementation"
  spec.description   = ""
  spec.homepage      = "https://github.com/mgpnd/shunting_yard"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/mgpnd/shunting_yard"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "debase"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "ruby-debug-ide"
end
