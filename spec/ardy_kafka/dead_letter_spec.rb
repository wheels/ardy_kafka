# frozen_string_literal: true

module ArdyKafka
  RSpec.describe DeadLetter do
    let(:payload) do
      {
        'created_at' => '2023-01-01 00:00:00',
        'arg' => 1
      }
    end
    let(:json_payload) { JSON.generate(payload) }
    let(:message_double) do
      instance_double('Rdkafka::Consumer::Message').tap do |message|
        allow(message).to receive(:payload).and_return(json_payload)
      end
    end
    let(:exception_double) do
      instance_double('StandardError').tap do |exception|
        allow(exception).to receive(:message).and_return('StandardError')
        allow(exception).to receive(:backtrace).and_return((1..10).to_a)
      end
    end
    let(:errors_topic) { 'my_errors_topic' }

    describe '#errors_payload' do
      context 'with an invalid payload' do
        let(:payload) { 'not parseable' }
        let(:unparseable_message_double) do
          instance_double('Rdkafka::Consumer::Message').tap do |message|
            allow(message).to receive(:payload).and_return(payload)
          end
        end
        let(:json_error_double) do
          instance_double('JSON::JSONError').tap do |exception|
            allow(exception).to receive(:message).and_return('JSON::JSONError')
            allow(exception).to receive(:backtrace).and_return((1..10).to_a)
          end
        end

        let(:dead_letter) { described_class.new(errors_topic, unparseable_message_double, json_error_double) }

        subject(:errors_payload) { dead_letter.send(:error_payload) }

        it 'returns the malformed payload and error metadata', :aggregate_failures do
          expect(errors_payload).to eq({
                                         'original_payload' => payload,
                                         'exception' => 'JSON::JSONError',
                                         'backtrace' => "1\n2\n3\n4\n5"
                                       })
        end
      end

      context 'with a valid payload' do
        let(:dead_letter) { described_class.new(errors_topic, message_double, exception_double) }

        subject(:errors_payload) { dead_letter.send(:error_payload) }

        it 'adds error metadata to the payload', :aggregate_failures do
          expect(errors_payload).to eq({
                                         'original_payload' => {
                                           'arg' => 1,
                                           'created_at' => '2023-01-01 00:00:00'
                                         },
                                         'exception' => 'StandardError',
                                         'backtrace' => "1\n2\n3\n4\n5"
                                       })
        end
      end
    end

    describe '#produce' do
      subject(:dead_letter) { described_class.new(errors_topic, message_double, exception_double) }

      it 'produces the message to the errors topic' do
        expect(dead_letter.producer).to receive(:produce).with(
          topic: dead_letter.errors_topic, payload: dead_letter.send(:error_payload)
        )

        dead_letter.produce
      end
    end
  end
end
