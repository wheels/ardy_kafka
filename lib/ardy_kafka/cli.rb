require 'singleton'
require 'optparse'
require 'ardy_kafka'

module ArdyKafka
  class CLI
    include Singleton

    attr_accessor :consumer, :config

    def run_consumer
      setup

      consumer.consume
    end

    def setup
      configure
      load_app
      validate_config
    end

    def configure
      @config = ArdyKafka.config
      opts = parse_cli_options
      @config.merge!(opts)
    end

    def parse_cli_options(argv = ARGV.dup)
      opts = {}
      parser = OptionParser.new do |opt|
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

    def load_app
      if defined?(::Rails)
        require File.expand_path("#{Dir.pwd}/config/environment.rb")
      else
        # ?
      end
    end
  end
end