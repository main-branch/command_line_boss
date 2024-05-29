# frozen_string_literal: true

require_relative "lib/command_line_boss/version"

Gem::Specification.new do |spec|
  spec.name = "command_line_boss"
  spec.version = CommandLineBoss::VERSION
  spec.authors = ["James Couball"]
  spec.email = ["jcouball@yahoo.com"]

  spec.summary = "Command Line Boss is a convenience layer over OptionsParser"
  spec.description = <<~DESCRIPTION
    Command Line Boss is a convenience layer over OptionsParser. It provides a simple
    way to define command line options and arguments, and then parse them into an options
    object.
  DESCRIPTION
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.homepage = "https://github.com/main-branch/command_line_boss"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/main-branch/command_line_boss"
  spec.metadata['changelog_uri'] = "https://rubydoc.info/gems/#{spec.name}/#{spec.version}/file/CHANGELOG.md"
  spec.metadata['documentation_uri'] = "https://rubydoc.info/gems/#{spec.name}/#{spec.version}"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  spec.add_development_dependency 'bundler-audit', '~> 0.9'
  spec.add_development_dependency "rake", "~> 13.2"
  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "rubocop", "~> 1.64"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
