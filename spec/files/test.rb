require 'bundler/setup'
require 'pilfer/logger'
require 'pilfer/profiler'
require 'stringio'

output   = StringIO.new
reporter = Pilfer::Logger.new(output)
profiler = Pilfer::Profiler.new(reporter)
path     = File.expand_path(File.dirname(__FILE__))

profiler.profile_files_matching(%r{^#{Regexp.escape(path)}}) do
  require 'hello'
  puts 'world!'
  10.times do
    sleep 0.01
  end
end
