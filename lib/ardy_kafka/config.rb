module ArdyKafka
  class Config
    attr_accessor :brokers, :producer_pool, :shutdown_timeout, :require, :env

    attr_reader :blocking_exceptions, :non_blocking_exceptions, :retries

    # Maps an opts hash to methods on the Config object.
    # @param [Hash] opts the options containing config key value pairs
    # @option opts [String] :brokers comma separated list of Kafka brokers
    # @option opts [Array<Class>] :blocking_exceptions an array of blocking exceptions
    # @option opts [Array<Class>] :non_blocking_exceptions an array of non-blocking exceptions
    # @option opts [Hash] :producer_pool a Hash containing the :size and :timeout for the producer pool
    # @option opts [Fixnum] :retries the number of retries for the message processor to attempt
    # @option opts [Fixnum] :shutdown_timeout amount of time in seconds to wait when shutting down the CLI process
    # @option opts [String] :require the path to the host app's main application file (non-Rails)
    # @option opts [String] :env the application environment
    def attributes=(opts)
      opts.each do |key, val|
        self.send("#{key}=", val)
      end
    end

    # Sets the list of blocking exceptions
    # @param list [Array<Class>] a list of blocking exceptions that will stop further processing
    # @raise [ArgumentError] if the list param is not an array
    # @return [Array]
    def blocking_exceptions=(list)
      raise ArgumentError, 'blocking_exceptions must be an Array' unless list.is_a?(Array)

      @blocking_exceptions = list
    end

    # Sets the list of non-blocking exceptions
    # @param list [Array<Class>]
    # @raise [ArgumentError] if the list param is not an array
    # @return [Array]
    def non_blocking_exceptions=(list)
      raise ArgumentError, 'non_blocking_exceptions must be an Array' unless list.is_a?(Array)

      @non_blocking_exceptions = list
    end

    # Sets the producer pool attributes
    # @param pool [Hash] the hash containing the producer pool settings
    # @option pool [Integer] :size the pool size
    # @option pool [Integer] :timeout the timeout in seconds
    # @raise [ArgumentError] if the list param is not an array
    # @raise [ArgumentError] if the keys are invalid
    # @return [Hash]
    def producer_pool=(pool)
      raise ArgumentError, 'producer_pool must be a Hash' unless pool.is_a?(Hash)
      raise ArgumentError, 'producer_pool valid keys are :size and :timeout' unless pool.keys.all? { |k| [:size, :timeout].include?(k) }

      #pool[:size] = Integer(pool[:size])
      #pool[:timeout] = Integer(pool[:timeout])

      @producer_pool = pool
    end

    def retries=(num)
      @retries = Integer(num)
    end
  end
end