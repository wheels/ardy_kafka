# ArdyKafka

ArdyKafka is a light framework to simplify using the [rdkafka-ruby](https://github.com/appsignal/rdkafka-ruby) gem.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add ardy_kafka

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install ardy_kafka

## Usage

### Configuring

```
ArdyKafka.configure do |config|
  c.brokers = 'broker:9092,broker:9093'
end
```

All other config options are optional:
* blocking_exceptions
* non_blocking_exceptions
* producer_pool (e.g. `{ size: 20, timeout: 3 }`)
* retries
* shutdown_timeout

### Producer

The `ArdyKafka::Producer` class should be called directly.

```
ArdyKafka::Producer.new.produce(topic: 'my_topic', payload: {arg: 1})
```

The primary useful features ArdyKafka provides are a pool of producer connections, sane default kafka configs and automatic JSON encoding.

### Consumer

TODO

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/ardy_kafka. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/ardy_kafka/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ArdyKafka project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/ardy_kafka/blob/master/CODE_OF_CONDUCT.md).
