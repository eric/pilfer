require 'helper'
require 'pilfer/profiler'

class TestPilferProfiler < MiniTest::Unit::TestCase
  def options()  {} end
  def checker()  lambda { true } end
  def profiler() lambda {|*args| @profiled = true } end

  def setup
    @profiled = false
  end

  def test_profiles_when_checker_returns_true
    checker  = lambda { true }
    Pilfer::Profiler.profile(options, checker, profiler) {}
    assert @profiled, 'profiler not called'
  end

  def test_does_not_profile_when_checker_returns_false
    checker  = lambda { false }
    Pilfer::Profiler.profile(options, checker, profiler) {}
    refute @profiled, 'profiler called'
  end

  def test_profiles_when_checker_is_nil
    checker  = nil
    Pilfer::Profiler.profile(options, checker, profiler) {}
    assert @profiled, 'profiler not called'
  end

  def test_profiler_returns_return_value_of_app
    profiler = lambda {|*args, &app|
      app.call
      :profiler_response
    }
    profile_response = Pilfer::Profiler.profile(options, checker, profiler) {
      :app_response
    }
    assert_equal :app_response, profile_response
  end

  def test_passes_file_matcher_to_profiler
    file_matcher = :file_matcher
    options      = { file_matcher: file_matcher }
    profiler     = MiniTest::Mock.new
    profiler.expect :call, nil, [file_matcher]
    Pilfer::Profiler.profile(options, checker, profiler)
    profiler.verify
  end

  def test_passes_uses_default_file_matcher_when_no_matcher_given
    expected_file_matcher = %r{^#{File.expand_path('.')}/(app|config|lib|vendor/plugin)}
    profiler     = MiniTest::Mock.new
    profiler.expect :call, nil, [expected_file_matcher]
    Pilfer::Profiler.profile(options, checker, profiler)
    profiler.verify
  end

  def test_default_file_matcher_anchors_at_app_root
    options = { app_root: '/dev/null' }
    expected_file_matcher = %r{^/dev/null/(app|config|lib|vendor/plugin)}
    profiler = MiniTest::Mock.new
    profiler.expect :call, nil, [expected_file_matcher]
    Pilfer::Profiler.profile(options, checker, profiler)
    profiler.verify
  end
end
