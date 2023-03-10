require_relative 'dead_letter'

module ArdyKafka
  class MessageProcessor
    attr_reader :consumer, :errors_topic

    class << self
      def blocking_exceptions
        ArdyKafka.config.blocking_exceptions
      end

      def non_blocking_exceptions
        ArdyKafka.config.non_blocking_exceptions
      end
    end

    # Instantiates a MessageProcessor. Expects a message dispatcher instance arg that responds to the method :dispatch
    #   and accepts a payload arg.
    # @param consumer [Object] an ArdyKafka::Consumer instance
    def initialize(consumer)
      @consumer = consumer
      @errors_topic = consumer.errors_topic
    end

    # Processes a Kafka message.
    #   Will attempt to delegate the message to the provided message dispatcher. All steps are wrapped in
    #   rescue blocks to prevent unexpected stoppages in message processing.
    #   If the message is not valid JSON and cannot be decoded, the message will be sent to the configured
    #   dead letters topic or discarded, and the error will be logged.
    #   If the message raises a blocking exception, the consumer will be paused and the process will briefly
    #   sleep. After resuming the consumer, message processing will be attempted again. This loop will continue
    #   infinitely.
    #   If the message raises a non-blocking exception, the message will be sent to the configured dead letters
    #   topic or discarded, and the error will be logged.
    #   If the message encounters any other StandardError, the message will be retried the configured number of
    #   times. Once the retries are exhausted, the message will be sent to the configured dead letters topic or
    #   discarded, and the error logged.
    # @param message [Object] an Rdkafka::Consumer::Message object
    def process(message)
      ArdyKafka.logger.info "Processing message on topic '#{message.topic}' at offset #{message.offset}"

      begin
        payload = ArdyKafka.decode_json(message.payload)

      rescue TypeError, JSON::JSONError => e
        ArdyKafka.logger.error "Encountered payload with invalid JSON: #{e.exception}"
        maybe_send_dead_letter(message, e)
        return message
      end

      attempts = 1
      retries = 0

      begin
        consumer.process(payload)

      rescue *MessageProcessor.blocking_exceptions => e
        ArdyKafka.logger.error "Encountered blocking error: #{e.exception}, attempts: #{attempts}"

        attempts += 1
        consumer.pause
        sleep 1 unless ArdyKafka.test_env?

        retry unless ArdyKafka.test_env?

      rescue *MessageProcessor.non_blocking_exceptions => e
        ArdyKafka.logger.error "Encountered non-blocking error: #{e.exception}"
        maybe_send_dead_letter(message, e)

      rescue StandardError => e
        if retries >= ArdyKafka.config.retries
          ArdyKafka.logger.error "Encountered retriable error: #{e.exception}, retries exhausted, ignoring message"
          maybe_send_dead_letter(message, e)
        else
          ArdyKafka.logger.error "Encountered retriable error: #{e.exception}, retries: #{retries}"
          retries += 1
          sleep retries**2 unless ArdyKafka.test_env?
          retry
        end

      ensure
        consumer.resume
      end
    end

    def maybe_send_dead_letter(message, exception)
      return unless errors_topic

      DeadLetter.produce(errors_topic, message, exception)
    end
  end
end