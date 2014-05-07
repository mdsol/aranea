require 'aranea/failure_repository'

module Aranea
  module Faraday

    class FailureSimulator

      def initialize(app, config = {})
        @app = app
        @config = config
      end

      def call(request_env)
        Rails.logger.info "Env: #{request_env}, App: #{@app}, config: #{@config}"
        puts "Env: #{request_env}, App: #{@app}, config: #{@config}"
        
        current_failure = Failure.current

        if current_failure.should_fail?(request_env, @app)
          #TODO: injectable logger
          puts "Aranea: simulating a failed call on #{request_env}"
          current_failure.respond!
        else
          @app.call(request_env)
        end

      end

    end

  end
end
