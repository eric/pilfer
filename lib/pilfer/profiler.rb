require 'rblineprof'

module Pilfer
  class Profiler
    attr_reader :reporter

    def initialize(reporter)
      @reporter = reporter
    end

    def profile(*args, &app)
      profile_files_matching(/./, *args, &app)
    end

    def profile_if(*args, &app)
      if args.shift
        profile(*args, &app)
      else
        app.call
      end
    end

    def profile_files_matching(matcher, description = nil,
                               reporter_options = {},
                               profiler = method(:lineprof),
                               start = Time.now, &app)
      app_response = nil
      profile = profiler.call(matcher) do
        app_response = app.call
      end
      reporter.write profile, start, description, reporter_options
      app_response
    end
  end
end
