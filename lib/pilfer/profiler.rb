require 'rblineprof'

# Pilfer::Profiler.profile(:app_root       => '/dev/null',
#                          :file_matcher   => %r{...},
#                          :service_url    => 'http://pilfer.com',
#                          :service_token  => 'abc123') {
#   do_something
# }

module Pilfer
  class Profiler
    attr_reader :app_root, :file_matcher

    def initialize(options)
      @app_root     = options[:app_root]     || File.expand_path('.')
      @file_matcher = options[:file_matcher] || default_file_matcher
    end

    def default_file_matcher
      %r{^#{app_root}/(app|config|lib|vendor/plugin)}
    end

    def self.profile(options, checker = nil, profiler = method(:lineprof), &app)
      if !checker || checker.call
        new(options).profile(profiler, app)
      else
        app.call
      end
    end

    def profile(profiler, app)
      app_response = nil
      profiler.call(file_matcher) do
        app_response = app.call
      end
      app_response
    end
  end
end
