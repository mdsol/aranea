# frozen_string_literal: true

module Aranea
  # TODO: Look into moving whitelisting of consumer hostnames to here and allowing it to be configurable
  # via the consuming application

  class Failure
    class << self
      def current
        retrieve_failure || NullFailure.new
      end

      def create(params)
        failure = retrieve_failure
        raise FailureFailure, "A failure is already in progress (#{failure})." if failure

        failure = new(params)
        Repository.store(failure, params[:minutes].minutes)
        failure
      end

      def retrieve_failure
        Repository.get
      end
    end

    attr_accessor :expiration_date

    def initialize(params)
      @pattern = Regexp.new(params[:pattern])
      @response = params[:failure]
      @response_hash = params[:response_hash] || {}
      @response_headers_hash = params[:response_headers_hash] || {}
    end

    def should_fail?(request_env, _app)
      @pattern.match(request_env[:url].to_s)
    end

    def respond!
      case @response
      when "timeout"
        raise ::Faraday::TimeoutError, "Fake failure from Aranea"
      when "ssl_error"
        raise ::Faraday::SSLError, "Fake failure from Aranea"
      else
        ::Faraday::Response.new(
          status: @response.to_i,
          body: @response_hash.to_json,
          response_headers: @response_headers_hash
        )
      end
    end

    def to_s
      "Failure on #{@pattern.inspect} ending at approximately #{@expiration_date}"
    end

    # TODO: Actually implement Repository pattern, dependency injection and all.
    # As is we only support sharing between multiple instances if Rails.cache exists and does
    class Repository
      KEY = "aranea_current_failure"

      class << self
        def store(failure, lifespan)
          failure.expiration_date = Time.now + lifespan
          cache.write(KEY, failure, expires_in: lifespan)
        end

        def get
          cache.read(KEY)
        end

        def clear
          cache.delete(KEY)
        end

        def cache
          @cache ||= rails_cache || memory_store
        end

        def rails_cache
          defined?(Rails.cache) && Rails.cache
        end

        def memory_store
          require "active_support/cache"
          ActiveSupport::Cache::MemoryStore.new
        end
      end
    end
  end

  class NullFailure
    def should_fail?(_request_env, _app)
      false
    end
  end
end
