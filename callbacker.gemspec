# frozen_string_literal: true

require_relative 'lib/callbacker/version'

Gem::Specification.new do |spec|
  spec.name = 'callbacker'
  spec.version = Callbacker::VERSION
  spec.authors = ['Ryan Cammer']
  spec.email = ['ryancammer@gmail.com']

  spec.summary = 'A place for callbacks.'
  spec.description = 'Callbacker provides a module for attaching before and after callbacks to code.'
  spec.homepage = 'https://github.com/ryancammer/callbacker'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.6.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/ryancammer/callbacker'
  spec.metadata['changelog_uri'] = 'https://github.com/ryancammer/callbacker/blob/master/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'rake', '~> 13.0'
  spec.add_dependency 'workflow', '~> 3.0'

  spec.add_development_dependency 'bundler', '~> 2.4', '>= 2.4.10'
  spec.add_development_dependency 'rspec', '~> 3.12'
  spec.add_development_dependency 'rubocop', '~> 1.49'
end
