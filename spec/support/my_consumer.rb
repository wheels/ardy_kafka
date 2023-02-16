class MyConsumer < ArdyKafka::Consumer
  consumer_config topics: ['my_topic'], group_id: 'my_group', errors_topic: 'my_topic_errors'

  def process(message)
  end
end