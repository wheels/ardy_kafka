require_relative '../ardy_kafka'
require_relative 'message_processor'

module ArdyKafka
  class Consumer
    attr_reader :driver_config, :driver_consumer, :topics, :errors_topic, :message_processor, :message_dispatcher
    attr_accessor :group_id, :paused_at

    # Instantiates a Consumer object. By default will provide a message processor but require the invoker to
    #   provide a message dispatcher. If the invoker provides a message processor the message dispatcher is unnecessary.
    # @param topics [Array<String>] the topics to consume from
    # @param group_id [String] the consumer group id passed to the kafka brokers
    # @param errors_topic [String, nil] the errors topic for routing unprocessable messages
    # @param message_processor_klass [Class] the message processing class for delegating message handling
    # @param message_dispatcher [Class] the message dispatcher that is injected into the message processor
    # @return [Object] the consumer object
    def initialize(topics:, group_id:, errors_topic: nil, message_processor_klass: ArdyKafka::MessageProcessor, message_dispatcher: nil)
      @driver_config = Rdkafka::Config.new(kafka_config)
      @driver_consumer = @driver_config.consumer
      @topics = topics
      @errors_topic = errors_topic
      @group_id = group_id

      raise ArgumentError, 'must provide a message_dispatcher if using the default message_processor_klass' if message_processor_klass == ArdyKafka::MessageProcessor && message_dispatcher.nil?

      @message_dispatcher = message_dispatcher
      @message_processor = message_processor_klass.new(self, @message_dispatcher)
    end

    def subscribe
      topics.each { |topic| driver_consumer.subscribe(topic) }
    end

    def consume
      subscribe
      driver_consumer.each do |message|
        message_processor.process(message)
        commit(message)
      end
    end

    def pause
      return if paused_at

      self.paused_at = Time.now.utc
      topic_partition_list = driver_consumer.assignment
      driver_consumer.pause(topic_partition_list)
    end

    def resume
      return unless paused_at

      self.paused_at = nil
      topic_partition_list = driver_consumer.assignment
      driver_consumer.resume(topic_partition_list)
    end

    def shutdown
      pause
      sleep ArdyKafka.config.shutdown_timeout
      driver_consumer.unsubscribe(topics)
      driver_consumer.close
    end

    private

    def kafka_config
      ArdyKafka.base_kafka_config.merge({
        :"group.id" => group_id,
        :"client.id" => client_id,
        :"enable.auto.offset.store" => false,
        :"auto.offset.reset" => 'earliest'
      })
    end

    def client_id
      "#{group_id} consumer"
    end

    def commit(message)
      consumer.store_offset(message)
    end
  end
end