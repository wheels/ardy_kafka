module ArdyKafka
  class Producer
    attr_reader :driver_producer, :result

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