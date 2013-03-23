require 'helper'
require 'json'
require 'stringio'
require 'pilfer/logger'

# reporter = Pilfer::Logger.new('pilfer.log')
# reporter = Pilfer::Logger.new($stdout, :app_root => '/my/app')
class TestPilferLogger < MiniTest::Unit::TestCase
  def test_writes_profile
    start   = Time.at(42)
    profile = {
      'one.rb' => [[1001052, 1001021, 19, 50, 28, 13],
                   [1001052, 50, 1]],
      'two.rb' => [[1001021, 0, 1001021, 28, 0, 28],
                   [0, 0, 0],
                   [1001021, 28, 1]]
    }
    expected = {
      'profile' => {
        'version'   => '0.2.5',
        'timestamp' => start.to_i,
        'files'     => {
          'one.rb' => {
            'total'         => 1001052,
            'child'         => 1001021,
            'exclusive'     => 19,
            'total_cpu'     => 50,
            'child_cpu'     => 28,
            'exclusive_cpu' => 13,
            'lines'         => {
              '0' => {
                'wall_time' => 1001052,
                'cpu_time'  => 50,
                'calls'     => 1
              }
            }
          },
          'two.rb' => {
            'total'         => 1001021,
            'child'         => 0,
            'exclusive'     => 1001021,
            'total_cpu'     => 28,
            'child_cpu'     => 0,
            'exclusive_cpu' => 28,
            'lines'         => {
              '1' => {
                'wall_time' => 1001021,
                'cpu_time'  => 28,
                'calls'     => 1
              }
            }
          }
        }
      }
    }
    report = StringIO.new
    Pilfer::Logger.new(report).write(profile, start)
    assert_equal expected, JSON.parse(report.string)
  end

  def test_omits_app_root
    profile = {
      '/my/app/one.rb' => [[1001052, 1001021, 19, 50, 28, 13],
                          [1001052, 50, 1]],
      '/my/app/two.rb' => [[1001021, 0, 1001021, 28, 0, 28],
                          [1001021, 28, 1]]
    }
    report = StringIO.new
    Pilfer::Logger.new(report, :app_root => '/my/app').
      write(profile, Time.now)
    keys = JSON.parse(report.string)['profile']['files'].keys
    assert_equal %w(one.rb two.rb), keys
  end

  def test_omits_app_root_with_trailing_separator
    profile = {
      '/my/app/one.rb' => [[1001052, 1001021, 19, 50, 28, 13],
                          [1001052, 50, 1]],
      '/my/app/two.rb' => [[1001021, 0, 1001021, 28, 0, 28],
                          [1001021, 28, 1]]
    }
    report = StringIO.new
    Pilfer::Logger.new(report, :app_root => '/my/app/').
      write(profile, Time.now)
    keys = JSON.parse(report.string)['profile']['files'].keys
    assert_equal %w(one.rb two.rb), keys
  end

  def test_only_removes_app_root_from_beginning_of_path
    profile = {
      '/my/app/one.rb' => [[1001052, 1001021, 19, 50, 28, 13],
                          [1001052, 50, 1]],
      '/my/app/two.rb' => [[1001021, 0, 1001021, 28, 0, 28],
                          [1001021, 28, 1]]
    }
    report = StringIO.new
    Pilfer::Logger.new(report, :app_root => '/app').
      write(profile, Time.now)
    keys = JSON.parse(report.string)['profile']['files'].keys
    assert_equal %w(/my/app/one.rb /my/app/two.rb), keys
  end
end
