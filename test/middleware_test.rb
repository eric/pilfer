# require 'rack/content_length'
# require 'rack/lint'
# require 'rack/mock'

require 'helper'
require 'rack/mock'
require 'pilfer/middleware'

class TestPilferMiddleware < MiniTest::Unit::TestCase
  def pilfer(app, options = {})
    options = { :service_url   => 'http://pilfer.app',
                :service_token => 'abc123'
              }.merge(options)

    Rack::Lint.new(Pilfer::Middleware.new(app, options))
  end

  def app
    lambda {|env| [200, {}, ["Don't Panic"]] }
  end

  def request
    Rack::MockRequest.env_for
  end

  def test_calls_downstream
    called = false
    app = lambda {|env|
      called = true
      [200, {}, ["Don't Panic"]]
    }

    pilfer(app).call(request)
    assert called, 'Downstream app not called'
  end
end
