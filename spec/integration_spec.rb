require 'helper'
require 'stringio'
require 'pilfer/logger'
require 'pilfer/profiler'

describe Pilfer do
  it 'integrates' do
    output   = StringIO.new
    reporter = Pilfer::Logger.new(output)
    Pilfer::Profiler.new(reporter).
      profile_files_matching(/integration_spec\.rb/, "testing") do
        10.times do
          sleep 0.01
        end
      end

    lines = output.string.split("\n")
    lines[0].should =~ %r{Profile start="[\d-]{10} [\d:]{8} UTC" description="testing"$}

    wall_time = lines[1].match(/wall_time=([\d\.]+)/)[1].to_f
    wall_time.should be_within(10).of(105)
  end
end
