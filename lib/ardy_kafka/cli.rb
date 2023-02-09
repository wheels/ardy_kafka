require 'singleton'
require 'optparse'
require 'ardy_kafka'

module ArdyKafka
  class CLI
    include Singleton unless ArdyKafka.test_env?

    attr_accessor :consumer, :config

    LOGGER_LEVEL_MAP = {
      'production' =>  Logger::INFO,
      'development' => Logger::DEBUG,
      'test' => Logger::DEBUG
    }
    LOGGER_LEVEL_MAP.default = LOGGER_LEVEL_MAP['production']
    LOGGER_LEVEL_MAP.freeze

    def run_consumer
      setup

      consumer.consume
    end

    def setup
      configure
      load_app
      set_env
      set_signal_handlers
      set_logger_level
      validate_config!
    end

    def configure
      @config = ArdyKafka.config
      opts = parse_cli_options
      @config.attributes(opts)
    end

    def parse_cli_options(argv = ARGV.dup)
      opts = {}
      parser = OptionParser.new do |opt|
        opt.on '-e', '--env ENV', 'Set the environment' do |arg|
          opts[:env] = String(arg)
        end

        opt.on '--require FILE', 'Host library/application file to require (non-Rails)' do |arg|
          opts[:require] = String(arg)
        end

        opt.on '--producer-pool-size NUM', 'Size of producer connection pool' do |arg|
          opts[:producer_pool] ||= {}
          opts[:producer_pool][:size] = Integer(arg)
        end

        opt.on '--producer-pool-timeout NUM', 'Timeout for producer connection pool' do |arg|
          opts[:producer_pool] ||= {}
          opts[:producer_pool][:timeout] = Integer(arg)
        end

        opt.on '--retries NUM', 'Number of retries attempted for retriable exceptions' do |arg|
          opts[:retries] = Integer(arg)
        end

        opt.on '--shutdown-timeout NUM', 'Amount of time to wait when shutting down consumer process' do |arg|
          opts[:shutdown_timeout] = Integer(arg)
        end

        opt.on '-v', '--version', 'Print version and exit' do |_arg|
          puts "ArdyKafka #{ArdyKafka::VERSION}"
          exit 0
        end
      end

      parser.banner = 'ArdyKafka [options]'
      parser.on_tail '-h', '--help', 'Show help' do
        puts parser
        exit 1
      end

      parser.parse!(argv)

      opts
    end

    def set_env
      @config.env ||= ENV["RAILS_ENV"] || ENV["RACK_ENV"] || ENV["APP_ENV"] || "development"
    end

    def load_app
      ENV["RAILS_ENV"] || ENV["RACK_ENV"] = @config.env

      if defined?(::Rails)
        require File.expand_path("#{Dir.pwd}/config/environment.rb")
      else
        require @config.require
      end
    end

    def set_signal_handlers
      sig_handlers = {
        'INT' => ->(_cli) { raise Interrupt },
        'TERM' => ->(_cli) { raise Interrupt },
        'TSTP' => lambda do |cli|
          cli.consumer.shutdown
        end
      }

      sig_handlers.each do |sig, handler|
        Signal.trap(sig) do
          handler.call(self)
        end
      end
    end

    def set_logger_level
      ArdyKafka.logger.level = LOGGER_LEVEL_MAP[@config.env]
    end

    def validate_config!
      raise ConfigError, 'brokers config is required' unless @config.brokers
    end
  end
end