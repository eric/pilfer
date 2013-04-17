require 'json'
require 'tempfile'
require 'pilfer/logger'

describe Pilfer::Logger do
  let(:spec_root) { File.expand_path('..', File.dirname(__FILE__)) }
  let(:profile) {
    profile_file    = File.join(spec_root, 'files', 'profile.json')
    profile_content = File.read(profile_file).gsub('SPEC_ROOT', spec_root)
    @profile        = JSON.parse(profile_content)
  }
  let(:reporter) { Tempfile.new('reporter') }
  let(:start)    { Time.at(42) }

  after do
    reporter.close
    reporter.unlink
  end

  def first_file_from_reporter
    reporter.
      read.
      split("\n\n")[1].
      split("\n").
      first.
      split(' ').
      first
  end

  describe '#write' do
    it 'writes profile to reporter' do
      expected = <<-EOS
##################################################
# 1970-01-01 00:00:42 UTC
##################################################

#{spec_root}/files/test.rb wall_time=113.7ms cpu_time=5.3ms
                   | require 'bundler/setup'
                   | require 'pilfer/logger'
                   | require 'pilfer/profiler'
                   | require 'stringio'
                   | 
                   | output   = StringIO.new
                   | reporter = Pilfer::Logger.new(output)
                   | profiler = Pilfer::Profiler.new(reporter)
                   | path     = File.expand_path(File.dirname(__FILE__))
                   | 
                   | profiler.profile_files_matching(%r{^\#{Regexp.escape(path)}}) do
     5.1ms (    3) |   require 'hello'
     0.0ms (    4) |   puts 'world!'
   108.6ms (    1) |   10.times do
   108.4ms (   10) |     sleep 0.01
                   |   end
                   | end

#{spec_root}/files/hello.rb wall_time=0.0ms cpu_time=0.0ms
     0.0ms (    2) | print 'Hello '

EOS
      Pilfer::Logger.new(reporter.path).write(profile, start)
      reporter.read.should eq(expected)
    end

    it 'omits app root' do
      Pilfer::Logger.new(reporter.path, :app_root => spec_root).
        write(profile, start)
      first_file_from_reporter.should eq('files/test.rb')
    end

    it 'omits app root with trailing separator' do
      Pilfer::Logger.new(reporter.path, :app_root => spec_root + '/').
        write(profile, start)
      first_file_from_reporter.should eq('files/test.rb')
    end

    it 'omits source of nonexistent files'
  end
end
