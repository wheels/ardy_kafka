# frozen_string_literal: true

require_relative 'ardy_kafka/version'
require_relative 'ardy_kafka/config'
require 'rdkafka'

module ArdyKafka
  DEFAULTS = {
    blocking_exceptions: [],
    non_blocking_exceptions: [],
    shutdown_timeout: 10
  }

  def self.configure(&block)
    raise ArgumentError, 'block required' unless block_given?

    config.defaults = DEFAULTS.dup

    yield config

    # validate?

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
end
