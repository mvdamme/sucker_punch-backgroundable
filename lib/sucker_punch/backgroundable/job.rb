module SuckerPunch
  module Backgroundable

    class Job
      include SuckerPunch::Job
      workers SuckerPunch::Backgroundable.configuration.workers
    
      def perform(receiver, method, args, options)
        receiver = load(receiver) if instantiate?(options)
        if defined?(ActiveRecord)
          ActiveRecord::Base.connection_pool.with_connection do
            receiver.send(method, *args)
          end
        else
          receiver.send(method, *args)
        end
      end
    
      def later(sec, *args)
        after(sec) { perform(*args) }
      end
      
      private
      
        def instantiate?(options)
          return true if SuckerPunch::Backgroundable.configuration.reload && !(!options[:reload].nil? && options[:reload] == false)
          options[:reload]
        end
        
        def load(receiver)
          receiver.respond_to?(:id) ? receiver.class.find(receiver.id) : receiver
        end
    end

  end
end