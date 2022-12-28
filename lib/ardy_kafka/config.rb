module ArdyKafka
  class Config
    attr_accessor :brokers, :shutdown_timeout, :producer_pool

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

      @producer_pool = pool
    end

    def retries=(num)
      @retries = Integer(num)
    end
  end
end