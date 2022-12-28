module ArdyKafka
  class Producer
    attr_reader :driver_producer, :result

    def produce(topic:, payload:)
      ArdyKafka.producer_pool.with do |producer|
        @driver_producer = producer
        @result = @driver_producer.produce(
          topic: topic,
          payload: ArdyKafka.encode_json(payload)
        ).wait
      end
    end
  end
end