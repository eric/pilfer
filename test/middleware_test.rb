require 'helper'
require 'rack/mock'
require 'pilfer/middleware'

class TestPilferMiddleware < MiniTest::Unit::TestCase
  def test_profiles_downstream
    service = Class.new do
      attr_accessor :options, :checker, :block
      def response()  :profile_response end
      def profiled?() @profiled end

      def profile(options, checker, &block)
        @profiled = true
        @options  = options
        @checker  = checker
        @block    = block
        response
      end
    end.new

    downstream_called = false
    downstream        = lambda {|env| downstream_called = true }
    service_options   = :service_options
    checker           = Proc.new {}

    app = Pilfer::Middleware.new(downstream, service_options, service, &checker)
    response = app.call(Rack::MockRequest.env_for)

    assert service.profiled?, '#profile not called'
    assert_equal service.response, response, '#profile response not returned'
    assert_equal service_options, service.options, 'Options not passed to #profile'
    assert_equal checker, service.checker, 'Checker not passed to #profile'
    refute service.block.nil?, 'Downstream call block not passed to #profile'

    refute downstream_called, 'Downstream called before #profile executed'
    service.block.call
    assert downstream_called, 'Downstream app not called'
  end
end
