require 'helper'
require 'rack/mock'
require 'pilfer/middleware'

describe Pilfer::Middleware do
  let(:env)      { Rack::MockRequest.env_for }
  let(:app)      { stub(:app, :call => nil) }
  let(:profiler) { stub(:profiler, :profile => nil) }
  let(:options)  {{ :profiler => profiler }}
  let(:guard)    { Proc.new do true end }
  subject { Pilfer::Middleware.new(app, options, &guard) }

  it 'profiles and calls the downstream app' do
    app.should_receive(:call).with(env).once
    profiler.should_receive(:profile).
      with("GET /", :submit => :async).and_yield
    subject.call(env)
  end

  it 'passes rack env to guard' do
    guard_args = nil
    guard = lambda do |*args| guard_args = args end

    Pilfer::Middleware.new(app, options, &guard).call(env)
    guard_args.should_not be_nil
    guard_args.size.should eq(1)
    guard_args.first.should eq(env)
  end

  context 'with file matcher' do
    let(:file_matcher) { stub(:file_matcher) }
    let(:options)      {{ :file_matcher => file_matcher,
                          :profiler     => profiler }}

    it 'passes file matcher to profiler and calls the downstream app' do
      app.should_receive(:call).with(env).once
      profiler.should_receive(:profile_files_matching).
        with(file_matcher, "GET /", :submit => :async).and_yield
      subject.call(env)
    end
  end

  context 'when guard returns false' do
    let(:guard) { Proc.new do false end }

    it 'calls the downstream app' do
      app.should_receive(:call).with(env).once
      subject.call(env)
    end

    it 'skips profiling' do
      profiler.should_not_receive(:profile)
      subject.call(env)
    end
  end

  context 'with no guard' do
    subject { Pilfer::Middleware.new(app, options) }

    it 'profiles and calls the downstream app' do
      profiler.should_receive(:profile).and_yield
      app.should_receive(:call).with(env)
      subject.call(env)
    end
  end
end
