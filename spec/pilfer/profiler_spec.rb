require 'helper'
require 'pilfer/profiler'

describe Pilfer::Profiler do
  let(:reporter) { stub(:reporter, :write => nil) }
  let(:start)    { stub(:start) }

  describe '#profile' do
    it 'profiles all files by default' do
      profiler = stub(:profiler)
      profiler.should_receive(:call).with(/./)
      Pilfer::Profiler.new(reporter).profile(profiler) { }
    end

    it 'returns value of app' do
      profiler = lambda {|*args, &app|
        app.call
        :profiler_response
      }

      response = Pilfer::Profiler.new(reporter).profile(profiler) {
        :app_response
      }

      response.should eq(:app_response)
    end

    it 'writes profile to reporter' do
      profiler = stub(:profiler, :call => :profiler_response)
      reporter.should_receive(:write).with(:profiler_response, start)
      Pilfer::Profiler.new(reporter).profile(profiler, start) { }
    end
  end

  describe '#profile_files_matching' do
    let(:matcher) { stub(:matcher) }

    it 'passes file matcher to profiler' do
      profiler = stub(:profiler)
      profiler.should_receive(:call).with(matcher)
      Pilfer::Profiler.new(reporter).
        profile_files_matching(matcher, profiler) { }
    end

    it 'writes profile to reporter' do
      profiler = stub(:profiler, :call => :profiler_response)
      reporter.should_receive(:write).with(:profiler_response, start)
      Pilfer::Profiler.new(reporter).
        profile_files_matching(matcher, profiler, start) { }
    end
  end
end
