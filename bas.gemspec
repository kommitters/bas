# frozen_string_literal: true

require_relative "lib/bas/version"

Gem::Specification.new do |spec|
  spec.name = "bas"
  spec.version = Bas::VERSION
  spec.authors = ["kommitters Open Source"]
  spec.summary = "BAS - Business automation system"

  spec.email = ["oss@kommit.co"]
  spec.description = "A versatile business automation system offering key components for building various use cases. \
    It provides an easy-to-use tool for implementing automation workflows without excessive complexity. \
    Formerly known as 'bns'."
  spec.homepage = "https://github.com/kommitters/bas"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/kommitters/bas"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
