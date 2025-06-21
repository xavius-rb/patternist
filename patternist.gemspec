# frozen_string_literal: true

require_relative 'lib/patternist/version'

Gem::Specification.new do |spec|
  spec.name     = 'patternist'
  spec.version  = Patternist::VERSION
  spec.authors  = ['Emerson Xavier']
  spec.email    = ['msxavii@gmail.com']

  spec.summary = 'Reusable utilities'
  spec.description = 'Reusable utilities for Ruby and Rails'
  spec.homepage = 'https://github.com/xavius-rb/patternist'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org/'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = 'https://github.com/xavius-rb/patternist/blob/main/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  # spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
  #  ls.readlines("\x0", chomp: true).reject do |f|
  #    (f == gemspec) ||
  #      f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
  #  end
  # end
  spec.files = Dir.glob('**/*', File::FNM_DOTMATCH).reject do |f|
    File.directory?(f) ||
      f == gemspec ||
      f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Uncomment to register a new dependency of your gem
  spec.add_dependency 'actionpack', '>= 4.0', '< 9.0'
end
