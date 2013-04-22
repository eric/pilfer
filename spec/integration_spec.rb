require 'helper'
require 'stringio'
require 'pilfer/logger'
require 'pilfer/profiler'

describe Pilfer do
  it 'integrates' do
    output   = StringIO.new
    reporter = Pilfer::Logger.new(output)
    Pilfer::Profiler.new(reporter).
      profile_files_matching(/integration_spec\.rb/) do
        10.times do
          sleep 0.01
        end
      end

    wall_time = output.string.split("\n")[1].
                  match(/wall_time=([\d\.]+)/)[1].to_f
    wall_time.should be_within(10).of(105)
  end
end
