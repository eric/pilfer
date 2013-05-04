require 'rblineprof'

module Pilfer
  class Profiler
    attr_reader :reporter

    def initialize(reporter)
      @reporter = reporter
    end

    def profile(description = nil, profiler = method(:lineprof),
                start = Time.now, &app)
      profile_files_matching(/./, description, profiler, start, &app)
    end

    def profile_files_matching(matcher, description = nil,
                               profiler = method(:lineprof),
                               start = Time.now, &app)
      app_response = nil
      profile = profiler.call(matcher) do
        app_response = app.call
      end
      reporter.write profile, start, description
      app_response
    end
  end
end
