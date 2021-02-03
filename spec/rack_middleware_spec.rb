require 'aranea/rack/aranea_middleware'
require 'timecop'

describe Aranea::Rack::FailureCreator do

  after do
    Aranea::Failure::Repository.clear
  end

  it 'passes normal requests through transparently' do

    @app = Object.new
    @env = {'REQUEST_METHOD' => 'GET', 'PATH_INFO' => '/widgets/1.json'}
    expect(@app).to receive(:call).with(@env.clone)

    described_class.new(@app).call(@env)

  end

  describe 'handling POST requests to /disable' do

    before do
      described_class.any_instance.stub(:puts)

      @app = Object.new
      @env = {'REQUEST_METHOD' => 'POST', 'PATH_INFO' => '/disable'}

      expect(@app).not_to receive(:call)
    end

    it 'responds with a 201 (created) message' do
      @env['QUERY_STRING'] = 'dependency=example'
      status, headers, response = described_class.new(@app).call(@env).flatten.to_a
      expect(status).to eq(201)
    end

    it 'uses defaults when optional arguments are not provided' do
      @env['QUERY_STRING'] = 'dependency=example'
      status, headers, response = described_class.new(@app).call(@env).flatten.to_a
      expect(response).to eq("For the next 5 minutes, all requests to urls containing 'example' will 500")
    end

    it 'uses optional arguments when provided' do
      @env['QUERY_STRING'] = 'dependency=example&minutes=10&failure=422&response=%7B%7D&headers=%7B%7D'
      status, headers, response = described_class.new(@app).call(@env).flatten.to_a
      expect(response).to eq("For the next 10 minutes, all requests to urls containing 'example' will 422")
    end

    it 'accepts timeout as a failure' do
      @env['QUERY_STRING'] = 'dependency=example&minutes=10&failure=timeout'
      status, headers, response = described_class.new(@app).call(@env).flatten.to_a
      expect(response).to eq("For the next 10 minutes, all requests to urls containing 'example' will timeout")
    end

    it 'accepts ssl_error as a failure' do
      @env['QUERY_STRING'] = 'dependency=example&minutes=10&failure=ssl_error'
      status, headers, response = described_class.new(@app).call(@env).flatten.to_a
      expect(response).to eq("For the next 10 minutes, all requests to urls containing 'example' will ssl_error")
    end

    it 'is case insensitive when accepting string-based failures' do
      @env['QUERY_STRING'] = 'dependency=example&minutes=10&failure=tImEoUt'
      status, headers, response = described_class.new(@app).call(@env).flatten.to_a
      expect(response).to eq("For the next 10 minutes, all requests to urls containing 'example' will timeout")
    end

    it 'properly sets the expiry' do
      @env['QUERY_STRING'] = 'dependency=example&minutes=10&failure=422'
      described_class.new(@app).call(@env)
      Timecop.travel(Time.now + 6.minutes) do
        expect(Aranea::Failure::Repository.get).to be
      end
      Timecop.travel(Time.now + 20.minutes) do
        expect(Aranea::Failure::Repository.get).not_to be
      end
    end

    it 'responds with an error unless a dependency is provided' do
      @env['QUERY_STRING'] = ''
      status, headers, response = described_class.new(@app).call(@env).flatten.to_a
      expect(response).to eq('Please provide a dependency to simulate failing')
    end

    it 'responds with an error on an unrecognized failure mode' do
      [200, 600, 'llama', ''].each do |failure|
        @env['QUERY_STRING'] = "dependency=example&failure=#{failure}"
        status, headers, response = described_class.new(@app).call(@env).flatten.to_a
        expect(response).to eq("failure should be a 4xx or 5xx status code, timeout, or ssl_error; got #{failure}")
      end
    end

    it 'responds with an error on a malformed minutes parameter' do
      [-1, 0.5, 'llama', '', 61].each do |minutes|
        @env['QUERY_STRING'] = "dependency=example&minutes=#{minutes}"
        status, headers, response = described_class.new(@app).call(@env).flatten.to_a
        expect(response).to eq("minutes should be an integer from 1 to 60, got #{minutes}")
      end
    end

    it 'responds with an error if a failure is already active' do
      @env['QUERY_STRING'] = 'dependency=example&minutes=60'
      described_class.new(@app).call(@env).last
      status, headers, response = described_class.new(@app).call(@env).flatten.to_a
      expect(status).to eq(422)
      expect(response).to match(%r[A failure is already in progress \(Failure on /example/ ending at approximately .+\).])
    end

    it 'catches and responds with any unexpected error' do
      described_class.any_instance.stub(:create_failure).and_raise(RuntimeError, 'Out of cheese')
      @env['QUERY_STRING'] = 'dependency=example'
      status, headers, response = described_class.new(@app).call(@env).flatten.to_a
      expect(response).to eq('Out of cheese')
    end

  end

end
