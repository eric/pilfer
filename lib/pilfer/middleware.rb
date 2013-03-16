module Pilfer
  class Middleware
    attr_reader :app, :service, :service_options, :checker

    def initialize(app, service_options = {}, service = Pilfer::Service, &checker)
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
