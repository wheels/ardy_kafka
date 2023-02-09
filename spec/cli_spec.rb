require 'spec_helper'

module ArdyKafka
  RSpec.describe CLI do
    describe '.configure' do
      before do
        ArdyKafka.reset_config!
        allow(ARGV).to receive(:dup).and_return(argv)
      end

      subject(:config) do
        cli = described_class.new
        cli.configure
        cli.config
      end

      context 'with no CLI options specified' do
        let(:argv) { ['async_task_consumer'] }

        it nil, :aggregate_failures do
          expect(config.brokers).to be nil
          expect(config.shutdown_timeout).to eq(ArdyKafka::DEFAULTS[:shutdown_timeout])
          expect(config.producer_pool[:size]).to eq(ArdyKafka::DEFAULTS[:producer_pool][:size])
          expect(config.producer_pool[:timeout]).to eq(ArdyKafka::DEFAULTS[:producer_pool][:timeout])
          expect(config.require).to be nil
          expect(config.blocking_exceptions).to be_empty
          expect(config.non_blocking_exceptions).to be_empty
          expect(config.retries).to eq(ArdyKafka::DEFAULTS[:retries])
        end
      end

      context 'with options' do
        let(:env) { 'development' }
        let(:require_path) { File.expand_path("#{Dir.pwd}/spec/support/dummy_require") }
        let(:pool_size) { 20 }
        let(:pool_timeout) { 10 }
        let(:retries) { 4 }
        let(:shutdown_timeout) { 20 }

        let(:argv) do
          [
            'async_task_consumer',
            '-e', env,
            '--require', require_path,
            '--producer-pool-size', pool_size.to_s,
            '--producer-pool-timeout', pool_timeout.to_s,
            '--retries', retries.to_s,
            '--shutdown-timeout', shutdown_timeout.to_s
          ]
        end

        it 'stores the config', :aggregate_failures do
          expect(config.env).to eq(env)
          expect(config.require).to eq(require_path)
          expect(config.producer_pool[:size]).to eq(pool_size)
          expect(config.producer_pool[:timeout]).to eq(pool_timeout)
          expect(config.retries).to eq(retries)
          expect(config.shutdown_timeout).to eq(shutdown_timeout)
        end
      end
    end

    describe '.load_app' do
      context 'when the host app is rails' do
      end

      context 'when the require config is specified' do
      end

      context 'when the require config is not specified' do
      end
    end

    describe '.set_signal_handlers' do
      # ¯\_(ツ)_/¯
    end

    describe '.set_logger_level' do
      context 'when no env var has been set' do
        before do
          ENV['RAILS_ENV'] = ENV['RACK_ENV'] = ENV['APP_ENV'] = nil
          cli = described_class.new
          cli.configure
          cli.set_env
          cli.set_logger_level
        end

        subject(:log_level) { ArdyKafka.logger.level }

        it 'uses the development / debug log level' do
          expect(log_level).to eq(Logger::DEBUG)
        end
      end

      context 'when the env var has been set' do
        before do
          ENV['RAILS_ENV'] = 'production'
          cli = described_class.new
          cli.configure
          cli.set_env
          cli.set_logger_level
        end

        subject(:log_level) { ArdyKafka.logger.level }

        it 'uses the level for the given env' do
          expect(log_level).to eq(Logger::INFO)
        end
      end
    end

    describe '.setup' do
      context 'with an invalid config' do
        subject(:cli) { described_class.new }

        xit 'raises an error' do
          expect { cli.setup }.to raise_error(ConfigError)
        end
      end

      context 'with config provided by the host app' do
        #
      end
    end
  end
end