module ArdyKafka
  class Config
    attr_accessor :brokers, :producer_pool, :shutdown_timeout, :require, :env

    attr_reader :blocking_exceptions, :non_blocking_exceptions, :retries

    def defaults=(defaults)
      defaults.each do |key, val|
        self.send("#{key}=", val)
      end
    end

    def blocking_exceptions=(list)
      raise ArgumentError, 'blocking_exceptions must be an Array' unless list.is_a?(Array)

      @blocking_exceptions = list
    end

    def non_blocking_exceptions=(list)
      raise ArgumentError, 'non_blocking_exceptions must be an Array' unless list.is_a?(Array)

      @non_blocking_exceptions = list
    end

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

    def merge!(opts)
      opts.each do |key, val|
        self.send("#{key}=", val)
      end
    end
  end
end