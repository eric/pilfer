require 'helper'
require 'stringio'
require 'pilfer'

describe Pilfer do
  context 'reporting to a Pilfer::Logger' do
    let(:reporter) { Pilfer::Logger.new(output) }
    let(:output)   { StringIO.new }

    it 'reports profile' do
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

    it 'ignores optional reporter args' do
      Pilfer::Profiler.new(reporter).
        profile_files_matching(/integration_spec\.rb/, "testing",
                               :report => :async) do
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

  context 'reporting to a Pilfer::Server' do
    it 'reports profile'
  end
end
