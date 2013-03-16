module Pilfer
  class Middleware
    attr_reader :app

    def initialize(app, options)
      @app = app
    end

    def call(env)
      app.call(env)
    end
  end
end
