# frozen_string_literal: true

RSpec.describe ArdyKafka do
  it "has a version number" do
    expect(ArdyKafka::VERSION).not_to be nil
  end

  describe '.configure' do
    subject(:config) { ArdyKafka.config }

    context 'with default settings' do
      before do
        ArdyKafka.configure { |c| }
      end

      it 'sets the defaults' do
        expect(config.blocking_exceptions).to eq(ArdyKafka::DEFAULTS[:blocking_exceptions])
        expect(config.non_blocking_exceptions).to eq(ArdyKafka::DEFAULTS[:non_blocking_exceptions])
        expect(config.producer_pool).to eq(ArdyKafka::DEFAULTS[:producer_pool])
        expect(config.shutdown_timeout).to eq(ArdyKafka::DEFAULTS[:shutdown_timeout])
      end
    end

    context 'with configurable settings' do
      let(:brokers) { 'localhost:9092' }
      let(:shutdown_timeout) { 20 }
      let(:blocking_exceptions) { [BlockingError] }
      let(:non_blocking_exceptions) { [NonBlockingError] }

      before do
        stub_const('::BlockingError', StandardError)
        stub_const('::NonBlockingError', StandardError)

        ArdyKafka.configure do |c|
          c.brokers = brokers
          c.shutdown_timeout = shutdown_timeout
          c.blocking_exceptions = blocking_exceptions
          c.non_blocking_exceptions = non_blocking_exceptions
        end
      end

      it 'stores the settings', :aggregate_failures do
        expect(config.brokers).to eq(brokers)
        expect(config.shutdown_timeout).to eq(shutdown_timeout)
        expect(config.blocking_exceptions).to eq(blocking_exceptions)
        expect(config.non_blocking_exceptions).to eq(non_blocking_exceptions)
      end
    end

    context 'with unconfigurable settings' do
      it 'raises an error' do
        expect do
          ArdyKafka.configure do |c|
            c.foo = 'bar'
          end
        end.to raise_error(NoMethodError)
      end
    end

    context 'with invalid settings' do
      it 'blocking_exceptions must be an array' do
        expect { ArdyKafka.configure { |c| c.blocking_exceptions = 'str' } }.to raise_error(ArgumentError)
      end

      it 'non_blocking_exceptions must be an array' do
        expect { ArdyKafka.configure { |c| c.non_blocking_exceptions = 'str' } }.to raise_error(ArgumentError)
      end

      it 'producer_pool must be a hash' do
        expect { ArdyKafka.configure { |c| c.producer_pool = [:size] } }.to raise_error(ArgumentError)
      end

      it 'producer_pool must be a hash with valid keys' do
        expect { ArdyKafka.configure { |c| c.producer_pool = { foo: 10 } } }.to raise_error(ArgumentError)
      end
    end
  end

  describe '.config' do
    it 'returns a config object' do
      expect(described_class.config).to be_a(ArdyKafka::Config)
    end
  end

  describe '.base_kafka_config' do
    before do
      ArdyKafka.configure do |c|
        c.brokers = 'localhost:9092'
      end
    end

    it do
      expect(described_class.base_kafka_config).to eq({
        :"bootstrap.servers" => 'localhost:9092'
      })
    end
  end

  describe '.producer_kafka_config' do
    before do |c|
      ArdyKafka.configure do |c|
        c.brokers = 'localhost:9092'
      end
    end

    it do
      expect(described_class.producer_kafka_config).to eq({
        :'bootstrap.servers' => 'localhost:9092',
        :'acks' => 'all',
        :'socket.timeout.ms' => 10_000
      })
    end
  end

  describe '.producer_pool' do
    subject(:producer_pool) { described_class.producer_pool }

    it do
      expect(producer_pool.size).to eq(10)
      expect(producer_pool.instance_variable_get(:@timeout)).to eq(5)
    end
  end
end
