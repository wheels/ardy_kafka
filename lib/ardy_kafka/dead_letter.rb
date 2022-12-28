module ArdyKafka
  class DeadLetter
    attr_reader :errors_topic, :message, :exception, :producer

    def self.produce(errors_topic, message, exception)
      new(errors_topic, message, exception).produce
    end

    def initialize(errors_topic, message, exception)
      @errors_topic = errors_topic
      @message = message
      @exception = exception
      @producer = ArdyKafka::Producer.new
    end

    def produce
      producer.produce(
        topic: errors_topic,
        payload: error_payload
      )
    end

    private

    def error_payload
      # Have to decode or it will double encode when creating the errors topic message
      original_payload = begin
        ArdyKafka.decode_json(message.payload)
      rescue TypeError, JSON::JSONError
        message.payload
      end

      {
        'original_payload' => original_payload,
        'exception' => exception.message,
        'backtrace' => exception.backtrace[0..4].join("\n")
      }
    end
  end
end