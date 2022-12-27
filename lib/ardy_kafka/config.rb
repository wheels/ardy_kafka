module ArdyKafka
  class Config
    attr_accessor :brokers, :shutdown_timeout, :blocking_exceptions, :non_blocking_exceptions

    def defaults=(defaults)
      defaults.each do |key, val|
        self.send("#{key}=", val)
      end
    end
  end
end