# frozen_string_literal: true

require "ardy_kafka"
require_relative '../lib/ardy_kafka/consumer'
require_relative '../lib/ardy_kafka/producer'
require_relative '../lib/ardy_kafka/cli'

ENV['ARDY_KAFKA_ENV'] = 'test'

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"]
  .sort
  .each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before do
    ArdyKafka.reset_config!

    ArdyKafka.configure do |c|
      c.brokers = ENV.fetch('ARDY_KAFKA_BROKERS', 'localhost:9092')
    end
  end
end

module ArdyKafka
  def self.reset_config!
    @config = Config.new.tap do |c|
      c.defaults = DEFAULTS
    end
  end
end