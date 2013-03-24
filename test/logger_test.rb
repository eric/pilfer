require 'helper'
require 'json'
require 'stringio'
require 'pilfer/logger'

# reporter = Pilfer::Logger.new('pilfer.log')
# reporter = Pilfer::Logger.new($stdout, :app_root => '/my/app')
class TestPilferLogger < MiniTest::Unit::TestCase
  attr_reader :test_root, :profile

  def setup
    @test_root      = File.expand_path(File.dirname(__FILE__))
    test_file       = File.join(test_root, 'files', 'profile.json')
    profile_content = File.read(test_file).gsub('TEST_ROOT', test_root)
    @profile        = JSON.parse(profile_content)
  end

  def test_writes_profile
    expected = <<-EOS
#{test_root}/files/test.rb
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

#{test_root}/files/hello.rb
     0.0ms (    2) | print 'Hello '

EOS
    report = StringIO.new
    Pilfer::Logger.new(report).write(profile, Time.at(42))
    assert_equal expected, report.string
  end

  def test_omits_app_root_with_trailing_separator
    expected = 'files/test.rb'
    report = StringIO.new
    Pilfer::Logger.new(report, :app_root => test_root + '/').
      write(profile, Time.at(42))
    first_line = report.string.split("\n").first
    assert_equal expected, first_line
  end

  def test_omits_app_root
    expected = 'files/test.rb'
    report = StringIO.new
    Pilfer::Logger.new(report, :app_root => test_root).
      write(profile, Time.at(42))
    first_line = report.string.split("\n").first
    assert_equal expected, first_line
  end
end
