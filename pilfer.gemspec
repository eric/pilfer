lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pilfer/version'

Gem::Specification.new do |spec|
  spec.name     = 'pilfer'
  spec.version  = Pilfer::VERSION
  spec.summary  = 'Look into your ruby with rblineprof'
  spec.authors  = ['Eric Lindvall',       'Larry Marburger']
  spec.email    = ['eric@sevenscale.com', 'larry@marburger.cc']
  spec.homepage = 'https://github.com/eric/pilfer'
  spec.license  = 'MIT'

  spec.files = %w(Gemfile LICENSE README.md)
  spec.files << 'pilfer.gemspec'
  spec.files += Dir.glob('lib/**/*.rb')
  spec.files += Dir.glob('spec/**/*.rb')
  spec.files += Dir.glob('script/*')
  spec.test_files = Dir.glob('spec/**/*.rb')

  spec.add_dependency 'rblineprof', '~> 0.3.2'
  spec.add_development_dependency 'bundler', '~> 1.0'

  spec.required_rubygems_version = '>= 1.3.6'
end
