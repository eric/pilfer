require 'pilfer/logger'
require 'pilfer/profiler'

module Pilfer
  class Middleware
    attr_accessor :app, :profiler, :file_matcher, :profile_guard

    def initialize(app, options = {}, &profile_guard)
      @app           = app
      @profiler      = options[:profiler] || default_profiler
      @file_matcher  = options[:file_matcher]
      @profile_guard = profile_guard
    end

    def call(env)
      if profile_guard.call(env)
        run_profiler(request_description(env)) { app.call(env) }
      else
        app.call(env)
      end
    end

    def run_profiler(description, &downstream)
      if file_matcher
        profiler.profile_files_matching(file_matcher, description,
                                        &downstream)
      else
        profiler.profile(description, &downstream)
      end
    end

    def default_profiler
      reporter = Pilfer::Logger.new($stdout, :app_root => ENV['PWD'])
      Pilfer::Profiler.new(reporter)
    end

    def request_description(env)
      [ env["REQUEST_METHOD"], env["PATH_INFO"] ].join(' ')
    end
  end
end
