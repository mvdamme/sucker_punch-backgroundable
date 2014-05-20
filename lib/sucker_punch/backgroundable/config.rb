# configuration, see http://robots.thoughtbot.com/mygem-configure-block.
module SuckerPunch
  module Backgroundable
    class << self
      attr_accessor :configuration
    end
  
    def self.configure
      self.configuration ||= Configuration.new
      yield(configuration)
    end
  
    class Configuration
      attr_accessor :enabled
      attr_accessor :workers
      attr_accessor :reload
  
      def initialize
        @enabled = true
        @workers = 2
        @reload = false
      end
    end
    
  end
end

SuckerPunch::Backgroundable.configure {}
