require 'aranea/faraday/aranea_middleware'

describe Aranea::Faraday::FailureSimulator do

  before do
    @app = Object.new
    @env = {}
    @app.stub(:config).and_return({'mauth_baseurl' => 'http://mauth-sandbox.imedidata.net'})
    stub_const("Aranea::WHITELISTED_BASEURIS", ["sandbox.imedidata.net"])
  end

  after do
    Aranea::Failure::Repository.clear
  end

  context 'no failure is active' do

    it 'passes requests through transparently' do
      expect(@app).to receive(:call).with(@env.clone)
      described_class.new(@app).call(@env)
    end

  end

  context 'a failure is active' do

    before do
      Aranea::Failure.create(pattern: 'yahoo|google', failure: '415', minutes: 100)
    end

    context 'the request does not match the specified pattern' do

      before do
        @env[:url] = 'https://www.bing.com/search?q=adorable+kittens&go=&qs=n&form=QBLH&pq=adorable+kittens'
      end

      it 'passes requests through transparently' do
        expect(@app).to receive(:call).with(@env.clone)
        described_class.new(@app).call(@env)
      end

    end

    context 'the request matches the specified pattern' do

      before do
        described_class.any_instance.stub(:puts)

        @env[:url] = 'https://www.google.com/search?q=adorable+kittens'
        expect(@app).not_to receive(:call)
      end

      it 'blocks the request from completing' do
        described_class.new(@app).call(@env)
      end

      it 'returns the specified response code' do
        described_class.new(@app).call(@env).status.should eq(415)
      end
    end

  end
  
  context 'the request does not have a whitelisted hostname' do
    
    before do
      @env[:url] = 'https://www.google.com/search?q=adorable+kittens'
      stub_const("Aranea::WHITELISTED_BASEURIS", ["blahblah.imedidata.net"])
    end
    
    it 'passes requests through transparently even if the request matches' do
      Aranea::Failure.create(pattern: 'google', failure: '415', minutes: 100)
      expect(@app).to receive(:call).with(@env.clone)
      described_class.new(@app).call(@env)
    end
  end

  context 'a timeout is simulated' do

    before do
      Aranea::Failure.create(pattern: 'yahoo|google', failure: 'timeout', minutes: 100)
      @env[:url] = 'https://www.google.com/search?q=adorable+kittens'
      described_class.any_instance.stub(:puts)
    end

    it 'throws a Faraday::Error::TimeoutError' do
      expect{described_class.new(@app).call(@env)}.to raise_error(Faraday::Error::TimeoutError)
    end

  end

end
