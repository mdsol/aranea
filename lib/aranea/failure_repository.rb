require 'faraday'
require 'active_support/core_ext/numeric/time'

module Aranea

  class Failure
    class << self

      def current
        retrieve_failure || NullFailure.new
      end

      def create(params)
        if failure = retrieve_failure
          raise FailureFailure, "A failure is already in progress (#{failure})."
        else
          failure = new(params)
          Repository.store(failure, params[:minutes].minutes)
          failure
        end
      end

      def retrieve_failure
        Repository.get
      end

    end

    attr_accessor :expiration_date

    def initialize(params)
      @pattern = Regexp.new(params[:pattern])
      @response = params[:failure]
    end

    def should_fail?(request_env)
      @pattern.match(request_env[:url])
    end

    def respond!
      if @response == 'timeout'
        raise ::Faraday::Error::TimeoutError, 'Fake failure from Aranea'
      else
        ::Faraday::Response.new(status: @response.to_i, body: 'Fake failure from Aranea', response_headers: {})
      end
    end

    def to_s
      "Failure on #{@pattern.inspect} ending at approximately #@expiration_date"
    end

    #TODO: Actually implement Repository pattern, dependency injection and all.
    # As is we only support sharing between multiple instances if Rails.cache exists and does
    class Repository
      @cache = if defined?(Rails::RAILS_CACHE) && Rails.cache
                  Rails.cache
                else
                  require 'active_support/cache'
                  ActiveSupport::Cache::MemoryStore.new
                end

      KEY = 'aranea_current_failure'

      class << self

        def store(failure, lifespan)
          failure.expiration_date = Time.now + lifespan
          @cache.write(KEY, failure, expires_in: lifespan)
        end

        def get
          @cache.read(KEY)
        end

        def clear
          @cache.delete(KEY)
        end

      end

    end

  end

  class NullFailure

    def should_fail?(request_env)
      false
    end

  end

end
