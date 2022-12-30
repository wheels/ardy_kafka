# frozen_string_literal: true

require_relative 'ardy_kafka/version'
require_relative 'ardy_kafka/config'
require_relative 'ardy_kafka/consumer'
require_relative 'ardy_kafka/producer'
require 'rdkafka'
require 'connection_pool'

module ArdyKafka
  DEFAULTS = {
    blocking_exceptions: [],
    non_blocking_exceptions: [],
    producer_pool: {
      size: 10,
      timeout: 5
    },
    retries: 3,
    shutdown_timeout: 10
  }

  def self.configure(&block)
    raise ArgumentError, 'block required' unless block_given?

    config.defaults = DEFAULTS.dup

    yield config

    config
  end

  def self.config
    @config ||= Config.new
  end

  def self.base_kafka_config
    {
      :"bootstrap.servers" => config.brokers
    }
  end

  def self.producer_kafka_config
    base_kafka_config.merge({
      :'acks' => 'all',
      :'socket.timeout.ms' => 10_000
    })
  end

  def self.producer_pool
    @producer_pool ||= ConnectionPool.new(size: config.producer_pool[:size], timeout: config.producer_pool[:timeout]) do
      config = producer_kafka_config
      Rdkafka::Config.new(config).producer
    end
  end

  def self.encode_json(obj)
    JSON.generate(obj)
  end

  def self.decode_json(str)
    JSON.parse(str)
  end

  def self.test_env?
    ENV['ARDY_KAFKA_ENV'] = 'test'
  end

  def logger
    return @logger if @logger

    @logger = Logger.new(STDOUT)
    @logger.level = Logger::WARN
    @logger
  end
end
