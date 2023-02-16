module ArdyKafka
  RSpec.describe MessageProcessor do
    let(:topics) { ['my_topic'] }
    let(:group_id) { 'my_consumer' }
    let(:message_payload) { { 'arg' => 1 } }
    let(:json_payload) { JSON.generate(message_payload) }
    let(:message_double) do
      instance_double(Rdkafka::Consumer::Message).tap do |message|
        allow(message).to receive(:payload).and_return(json_payload)
        allow(message).to receive(:topic).and_return(topics.first)
        allow(message).to receive(:offset).and_return(1)
      end
    end
    let(:errors_topic) { 'my_errors_topic' }
    let(:consumer) do
      MyConsumer.consumer_config(topics: topics, group_id: group_id)
      MyConsumer.new
    end

    describe '#process' do
      let(:message_processor) { described_class.new(consumer) }

      subject(:process) { message_processor.process(message_double) }

      context 'with a payload that is invalid' do
        context 'when the type' do
          let(:json_payload) { nil }

          it 'sends the message to dead letters' do
            expect(DeadLetter).to receive(:produce).with(errors_topic, message_double, TypeError)
            process
          end
        end

        context 'when it is unparseable' do
          let(:json_payload) { 'unparseable as JSON' }

          it 'sends the message to dead letters' do
            expect(DeadLetter).to receive(:produce).with(errors_topic, message_double, JSON::JSONError)
            process
          end
        end
      end

      context 'when a message raises a blocking exception' do
        before do
          stub_const('::PGConnectionBad', StandardError)

          ArdyKafka.configure do |config|
            config.blocking_exceptions = [exception]
          end

          allow(consumer).to receive(:process).with(message_payload).and_raise(exception)
        end

        let(:exception) { PGConnectionBad }

        # TODO: simluate the job recovering instead of short-circuiting the retry call in test env
        it 'pauses the consumer while retrying and resumes after', :aggregate_failures do
          expect(consumer).to receive(:process).with(message_payload)
          expect(consumer).to receive(:pause)
          expect(consumer).to receive(:resume)
          process
        end

        xit 'does not send to dead letters and warns instead of raising the error', :aggregate_failures do
          expect(message_processor).not_to receive(:maybe_send_dead_letter)
          expect { process }.not_to raise_error
        end
      end

      context 'when a message raises a non-blocking exception' do
        let(:exception) { RecordNotFound }

        before do
          stub_const('::RecordNotFound', StandardError)
          allow(consumer).to receive(:process).with(message_payload).and_raise(exception)
        end

        it 'sends the message to dead letters and warns instead of raising the error', :aggregate_failures do
          expect(consumer).to receive(:process).with(message_payload)
          expect(DeadLetter).to receive(:produce).with(errors_topic, message_double, exception)
          expect { process }.not_to raise_error
        end
      end

      context 'when a message raises a retriable exception' do
        before do
          stub_const('::ThirdPartyApiError', StandardError)

          allow(consumer).to receive(:process).with(message_payload).twice.and_raise(exception)
          allow(consumer).to receive(:process).with(message_payload).once
        end

        let(:exception) { ThirdPartyApiError }

        context 'when recovers' do
          xit 'retries until succeeding, does not send to dead letters', :aggregate_failures do
            expect(consumer).to receive(:process).with(message_payload).exactly(3).times
            expect(DeadLetter).not_to receive(:produce)
            process
          end
        end

        context 'when cannot recover' do
          before do
            allow(consumer).to receive(:process).with(message_payload).exactly(4).times.and_raise(exception)
          end

          it 'warns with the error and retries the job', :aggregate_failures do
            expect(consumer).to receive(:process).with(message_payload)
            process
          end

          it 'sends the message to dead letters after exhausting retries', :aggregate_failures do
            expect(consumer).to receive(:consumer).with(message_payload)
            expect(DeadLetter).to receive(:produce).with(errors_topic, message_double, exception)
            process
          end
        end
      end

      context 'with a valid payload that can be processed' do
        it 'performs the job' do
          expect(consumer).to receive(:process)#.with(message_payload).once
          process
        end

        it 'deregisters the job after performing', :aggregate_failures do
          expect(consumer).to receive(:process)#.with(message_payload).once
          process
        end
      end
    end

    describe '#maybe_send_dead_letter' do

    end
  end
end