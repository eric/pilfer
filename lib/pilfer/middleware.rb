require 'pilfer/service'

# use(Pilfer::Middleware, :app_root       => '/dev/null',
#                         :file_matcher   => %r{...},
#                         :service_url    => 'http://pilfer.com',
#                         :service_token  => 'abc123') do
#   run_profile?
# end
module Pilfer
  class Middleware
    attr_reader :app, :service, :service_options, :checker

    def initialize(app, service_options = {}, service = Pilfer::Profiler, &checker)
      @app = app
      @service_options = service_options
      @service = service
      @checker = checker
    end

    def call(env)
      @service.profile(service_options, checker) { app.call(env) }
    end
  end
end
