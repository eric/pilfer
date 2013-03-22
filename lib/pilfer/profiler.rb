# require 'rblineprof'

module Pilfer
  class Profiler
    attr_reader :reporter

    def initialize(reporter)
      @reporter = reporter
    end

    def profile(profiler = method(:lineprof), &app)
      profile_files_matching(/./, profiler, &app)
    end

    def profile_files_matching(matcher, profiler = method(:lineprof), &app)
      app_response = nil
      profile = profiler.call(matcher) do
        app_response = app.call
      end
      reporter.write profile
      app_response
    end
  end
end
