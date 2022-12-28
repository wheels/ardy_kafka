require 'spec_helper'

module ArdyKafka
  RSpec.describe Consumer do
    let(:topics) { ['my_topic'] }
    let(:group_id) { 'my_consumer' }
    let(:errors_topic) { 'my_topic_errors' }

    subject(:consumer) do
      Consumer.new(
        topics: topics,
        group_id: group_id,
        errors_topic: errors_topic,
        message_dispatcher: MyMessageDispatcher.new
      )
    end

    before do
      # Ensure topics are created
      topics.each do |t|
        Producer.new.produce(topic: t, payload: '')
      end
    end

    describe '.initialize' do
      it 'sets the given attributes', :aggregate_failures do
        expect(consumer.topics).to eq(topics)
        expect(consumer.group_id).to eq(group_id)
        expect(consumer.errors_topic).to eq(errors_topic)
      end

      it 'sets the other attributes' do
        expect(consumer.driver_config).to be_a(Rdkafka::Config)
        expect(consumer.driver_consumer).to be_a(Rdkafka::Consumer)
      end

      context 'with the default message processor and no message dispatcher' do
        it 'raises an error' do
          expect { Consumer.new(topics: topics, group_id: group_id) }.to raise_error(ArgumentError)
        end
      end
    end

    describe '#consume' do
      # how to test a blocking call?
    end

    describe '#pause' do
      before do
        # consumer.subscribe
      end

      context 'when not paused' do
        it 'sets the paused_at attr' do
          expect { consumer.pause }.to change { consumer.paused_at }.from(nil)
          expect(consumer.paused_at).not_to be_nil
        end
      end

      context 'when paused' do
        before do
          consumer.pause
        end

        it 'does nothing' do
          expect { consumer.pause }.not_to change { consumer.paused_at }
        end
      end
    end

    describe '#resume' do
      before do
        # consumer.subscribe
      end

      context 'when paused' do
        before do
          consumer.pause
        end

        it 'resets paused_at' do
          expect { consumer.resume }.to change { consumer.paused_at }.to(nil)
        end
      end

      context 'when not paused' do
        it 'does nothing' do
          expect { consumer.resume }.not_to change { consumer.paused_at }
        end
      end
    end

    describe '#kafka_config' do
      subject(:kafka_config) { consumer.send(:kafka_config) }

      it nil, :aggregate_failures do
        expect(kafka_config[:'bootstrap.servers']).not_to be_nil
        expect(kafka_config[:'group.id']).to eq(group_id)
        expect(kafka_config[:'client.id']).to eq(consumer.send(:client_id))
        expect(kafka_config[:'enable.auto.offset.store']).to be false
        expect(kafka_config[:'auto.offset.reset']).to eq('earliest')
      end
    end
  end
end