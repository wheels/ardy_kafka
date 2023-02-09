module ArdyKafka
  class Producer
    attr_reader :driver_producer, :result

    # Produces a message with the given arguments
    # @param topic [String] the topic to which the message will be produced
    # @param payload [String] the message payload
    # @param key [String] the message key
    # @param partition [Integer] the topic partition
    # @param partition_key [String] the topic partition key
    # @param timestamp [Time,Integer] the timestamp of the message
    # @param headers [Hash] the message headers
    def produce(topic:, payload: nil, key: nil, partition: nil, partition_key: nil, timestamp: nil, headers: nil)
      ArdyKafka.producer_pool.with do |producer|
        @driver_producer = producer
        @result = @driver_producer.produce(
          topic: topic,
          payload: ArdyKafka.encode_json(payload),
          key: key,
          partition: partition,
          partition_key: partition_key,
          timestamp: timestamp,
          headers: headers
        ).wait
      end
    end
  end
end