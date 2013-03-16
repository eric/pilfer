lib = 'pilfer'
lib_file = File.expand_path("../lib/#{lib}.rb", __FILE__)
File.read(lib_file) =~ /\bVERSION\s*=\s*["'](.+?)["']/
version = $1

Gem::Specification.new do |spec|
  spec.name     = lib
  spec.version  = version

  spec.summary  = "Look into your ruby with rblineprof."

  spec.authors  = ["Eric Lindvall", "Larry Marburger"]
  spec.email    = 'larry@marburger.cc'
  spec.homepage = 'https://github.com/eric/pilfer'
  spec.license  = 'MIT'

  spec.files = %w(Gemfile LICENSE Rakefile README.md)
  spec.files << "#{lib}.gemspec"
  spec.files += Dir.glob("lib/**/*.rb")
  spec.files += Dir.glob("script/*")

  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rack', '~> 1.5.2'

  dev_null    = File.exist?('/dev/null') ? '/dev/null' : 'NUL'
  git_files   = `git ls-files -z 2>#{dev_null}`
  spec.files &= git_files.split("\0") if $?.success?
end
