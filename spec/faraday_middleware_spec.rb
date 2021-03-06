# frozen_string_literal: true

RSpec.describe Aranea::Faraday::FailureSimulator do
  before do
    @app = double(:call)
    @env = {}
  end

  after do
    Aranea::Failure::Repository.clear
  end

  context "no failure is active" do
    it "passes requests through transparently" do
      expect(@app).to receive(:call).with(@env.clone)
      described_class.new(@app).call(@env)
    end
  end

  context "a failure is active" do
    let(:pattern) { "yahoo|google" }
    let(:failure) { 415 }
    let(:minutes) { 100 }
    let(:response_hash) { { hello: "there" } }
    let(:response_headers_hash) { { "Content-type" => "application/json" } }

    before do
      Aranea::Failure.create(
        pattern: pattern,
        failure: failure,
        minutes: minutes,
        response_hash: response_hash,
        response_headers_hash: response_headers_hash
      )
    end

    context "the request does not match the specified pattern" do
      before do
        @env[:url] = "https://www.bing.com/search?q=adorable+kittens&go=&qs=n&form=QBLH&pq=adorable+kittens"
      end

      it "passes requests through transparently" do
        expect(@app).to receive(:call).with(@env.clone)
        described_class.new(@app).call(@env)
      end
    end

    context "the request matches the specified pattern" do
      before do
        allow_any_instance_of(described_class).to receive(:puts)

        @env[:url] = "https://www.google.com/search?q=adorable+kittens"
        expect(@app).not_to receive(:call)
      end

      it "blocks the request from completing" do
        described_class.new(@app).call(@env)
      end

      it "returns the specified response code, headers, and body" do
        response = described_class.new(@app).call(@env)
        expect(response.status).to eq(415)
        expect(response.body).to eq(response_hash.to_json)
        expect(response.headers).to include(response_headers_hash)
      end
    end
  end

  context "a timeout is simulated" do
    before do
      Aranea::Failure.create(pattern: "yahoo|google", failure: "timeout", minutes: 100)
      @env[:url] = "https://www.google.com/search?q=adorable+kittens"
      allow_any_instance_of(described_class).to receive(:puts)
    end

    it "throws a Faraday::TimeoutError" do
      expect { described_class.new(@app).call(@env) }.to raise_error(Faraday::TimeoutError)
    end
  end

  context "when an SSL error is simulated" do
    before do
      Aranea::Failure.create(pattern: "yahoo|google", failure: "ssl_error", minutes: 100)
      @env[:url] = "https://www.google.com/search?q=adorable+puppies"
      allow_any_instance_of(described_class).to receive(:puts)
    end

    it "throws a Faraday::SSLError" do
      expect { described_class.new(@app).call(@env) }.to raise_error(Faraday::SSLError)
    end
  end
end
