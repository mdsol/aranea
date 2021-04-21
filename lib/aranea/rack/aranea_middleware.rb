# frozen_string_literal: true

module Aranea
  FailureFailure = Class.new(RuntimeError)

  ALLOWED_MINUTES = (1..60).freeze

  module Rack
    class FailureCreator
      def initialize(app, config = {})
        @app = app
        @config = config
      end

      def call(env)
        if failure_creation_request?(env)
          response = begin
            [create_failure(::Rack::Utils.parse_query(env["QUERY_STRING"])), 201, {}]
          rescue FailureFailure => e
            [e.message, 422, {}]
          rescue => e
            [e.message, 500, {}]
          end
          ::Rack::Response.new(*response).finish
        else
          @app.call(env)
        end
      end

      protected

      def failure_creation_request?(env)
        env["REQUEST_METHOD"] == "POST" && env["PATH_INFO"] == "/disable"
      end

      def create_failure(options)
        dependency = options.fetch("dependency") do
          raise FailureFailure, "Please provide a dependency to simulate failing"
        end
        minutes    = options.fetch("minutes", 5)
        failure    = options.fetch("failure", "500")
        response   = options.fetch("response", "{}") # Expect URI encoded
        headers    = options.fetch("headers", "{}")

        # These will emit a parsing error if the response/headers URI encoded string is malformed.
        response_hash = JSON.parse(CGI.unescape(response)).to_hash
        response_headers_hash = JSON.parse(CGI.unescape(headers)).to_hash

        unless failure =~ /\A((4|5)\d\d|timeout|ssl_error)\Z/i
          raise FailureFailure, "failure should be a 4xx or 5xx status code, timeout, or ssl_error; got #{failure}"
        end

        unless ALLOWED_MINUTES.cover?(minutes.to_i)
          raise FailureFailure,
            "minutes should be an integer from #{ALLOWED_MINUTES.begin} to #{ALLOWED_MINUTES.end}, got #{minutes}"
        end

        Failure.create(
          pattern: dependency,
          minutes: minutes.to_i,
          failure: failure,
          response_hash: response_hash,
          response_headers_hash: response_headers_hash
        )

        result = "For the next #{minutes} minutes, all requests to urls containing '#{dependency}' " \
          "will #{failure.downcase}"

        # TODO: injectable logger
        puts "Aranea: #{result}"

        result
      end
    end
  end
end
