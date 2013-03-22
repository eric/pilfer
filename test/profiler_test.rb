require 'helper'
require 'pilfer/profiler'

class TestPilferProfiler < MiniTest::Unit::TestCase
  def setup
    @reporter = Class.new do
      def write(*args) end
    end.new

    @profiler = lambda {|*args| @profiled = true }
    @profiled = false
  end

  def test_profiles
    Pilfer::Profiler.new(@reporter).profile(@profiler) { }
    assert @profiled, 'profiler not called'
  end

  def test_profiler_returns_return_value_of_app
    profiler = lambda {|*args, &app|
      app.call
      :profiler_response
    }
    response = Pilfer::Profiler.new(@reporter).profile(profiler) {
      :app_response
    }
    assert_equal :app_response, response
  end

  def test_profiles_all_files_by_default
    profiler = MiniTest::Mock.new
    profiler.expect :call, nil, [/./]
    Pilfer::Profiler.new(@reporter).profile(profiler) { }
    profiler.verify
  end

  def test_passes_file_matcher_to_profiler
    matcher  = :matcher
    profiler = MiniTest::Mock.new
    profiler.expect :call, nil, [matcher]
    Pilfer::Profiler.new(@reporter).
      profile_files_matching(matcher, profiler) { }
    profiler.verify
  end

  def test_writes_profile_to_reporter
    profiler = lambda {|*args, &app|
      app.call
      :profiler_response
    }
    reporter = MiniTest::Mock.new
    reporter.expect :write, nil, [:profiler_response]
    Pilfer::Profiler.new(reporter).profile(profiler) { }
    reporter.verify
  end
end
