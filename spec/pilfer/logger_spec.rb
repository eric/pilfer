require 'json'
require 'json'
require 'stringio'
require 'pilfer/logger'

describe Pilfer::Logger do
  let(:spec_root) { File.expand_path('..', File.dirname(__FILE__)) }
  let(:profile) {
    profile_file    = File.join(spec_root, 'files', 'profile.json')
    profile_content = File.read(profile_file).gsub('SPEC_ROOT', spec_root)
    @profile        = JSON.parse(profile_content)
  }

  describe '#write' do
    it 'writes profile to reporter' do
      expected = <<-EOS
#{spec_root}/files/test.rb
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

#{spec_root}/files/hello.rb
     0.0ms (    2) | print 'Hello '

EOS
      reporter = StringIO.new
      Pilfer::Logger.new(reporter).write(profile, Time.at(42))
      reporter.string.should eq(expected)
    end

    it 'omits app root' do
      reporter = StringIO.new
      Pilfer::Logger.new(reporter, :app_root => spec_root).
        write(profile, Time.at(42))
      first_line = reporter.string.lines.first.chomp
      first_line.should eq('files/test.rb')
    end

    it 'omits app root with trailing separator' do
      reporter = StringIO.new
      Pilfer::Logger.new(reporter, :app_root => spec_root + '/').
        write(profile, Time.at(42))
      first_line = reporter.string.lines.first.chomp
      first_line.should eq('files/test.rb')
    end
  end
end
