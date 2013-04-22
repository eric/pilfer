require 'helper'
require 'json'
require 'tempfile'
require 'pilfer/logger'

describe Pilfer::Logger do
  let(:spec_root) { File.expand_path('..', File.dirname(__FILE__)) }
  let(:profile)   {
    profile_file    = File.join(spec_root, 'files', 'profile.json')
    profile_content = File.read(profile_file).gsub('SPEC_ROOT', spec_root)
    JSON.parse(profile_content)
  }
  let(:reporter) { StringIO.new }
  let(:start)    { Time.at(42) }
  let(:output) {
    reporter.string.each_line.map {|line|
      line.sub(/I, \[[^\]]+\]  INFO -- : /, '')
    }.join
  }
  let(:first_file) {
    output.
      split("\n")[1].
      split(' ').
      first
  }

  describe '#write' do
    it 'writes profile to reporter' do
      expected = <<-EOS
Profile start=1970-01-01 00:00:42 UTC
#{spec_root}/files/hello.rb wall_time=0.0ms cpu_time=0.0ms
     0.0ms (    2) | print 'Hello '
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
EOS
      Pilfer::Logger.new(reporter).write(profile, start)
      output.should eq(expected)
    end

    it 'omits app root' do
      Pilfer::Logger.new(reporter, :app_root => spec_root).
        write(profile, start)
      first_file.should eq('files/hello.rb')
    end

    it 'omits app root with trailing separator' do
      Pilfer::Logger.new(reporter, :app_root => spec_root + '/').
        write(profile, start)
      first_file.should eq('files/hello.rb')
    end

    context 'with a nonexistent file' do
      let(:profile) {{
        "(eval)" => [[113692, 31, 5026, 5313, 18, 4868], [0, 0, 0]]
      }}

      it 'omits the source of the nonexistent file' do
        expected = <<-EOS
Profile start=1970-01-01 00:00:42 UTC
(eval) wall_time=113.7ms cpu_time=5.3ms
EOS
        Pilfer::Logger.new(reporter).write(profile, start)
        output.should eq(expected)
      end
    end

    it 'appends to the log file' do
      3.times { Pilfer::Logger.new(reporter).write(profile, start) }
      output.scan('Profile start=').size.should eq(3)
    end
  end
end
