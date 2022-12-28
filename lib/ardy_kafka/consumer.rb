require_relative '../ardy_kafka'
require_relative 'message_processor'

module ArdyKafka
  class Consumer
    attr_reader :driver_config, :driver_consumer, :topics, :errors_topic, :message_processor, :message_dispatcher
    attr_accessor :group_id, :paused_at

    def initialize(topics:, group_id:, errors_topic: nil, message_processor_klass: ArdyKafka::MessageProcessor, message_dispatcher: nil)
      @driver_config = Rdkafka::Config.new(kafka_config)
      @driver_consumer = @driver_config.consumer
      @topics = topics
      @errors_topic = errors_topic
      @group_id = group_id

      raise ArgumentError, 'must provide a message_dispatcher if using the default message_proessor_klass' if message_processor_klass == ArdyKafka::MessageProcessor && message_dispatcher.nil?

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