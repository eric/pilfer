require 'helper'
require 'pilfer/profiler'

describe Pilfer::Profiler do
  let(:reporter)         { stub(:reporter, :write => nil) }
  let(:reporter_options) { stub(:reporter_options) }
  let(:description)      { stub(:description) }
  let(:profiler)         { stub(:profiler, :call => :profiler_response) }
  let(:start)            { stub(:start) }

  describe '#profile' do
    it 'profiles all files by default' do
      profiler.should_receive(:call).with(/./)
      Pilfer::Profiler.new(reporter).
        profile(description, reporter_options, profiler) { }
    end

    it 'returns value of app' do
      profiler = lambda {|*args, &app|
        app.call
        :profiler_response
      }

      response = Pilfer::Profiler.new(reporter).
        profile(description, reporter_options, profiler) { :app_response }

      response.should eq(:app_response)
    end

    it 'writes profile to reporter' do
      reporter.should_receive(:write).
        with(:profiler_response, start, description, reporter_options)
      Pilfer::Profiler.new(reporter).
        profile(description, reporter_options, profiler, start) { }
    end
  end

  describe '#profile_files_matching' do
    let(:matcher) { stub(:matcher) }

    it 'passes file matcher to profiler' do
      profiler.should_receive(:call).with(matcher)
      Pilfer::Profiler.new(reporter).
        profile_files_matching(matcher, description, reporter_options,
                               profiler) { }
    end

    it 'writes profile to reporter' do
      reporter.should_receive(:write).
        with(:profiler_response, start, description, reporter_options)
      Pilfer::Profiler.new(reporter).
        profile_files_matching(matcher, description, reporter_options,
                               profiler, start) { }
    end
  end
end
