require 'spec_helper'

module ArdyKafka
  RSpec.describe Config do 
    it 'instantiates' do
      expect(Config.new).to be_a(Config)
    end
  end
end