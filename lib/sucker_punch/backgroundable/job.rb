module SuckerPunch
  module Backgroundable

    module CallMethod
      private
      
        def instantiate?(options)
          return true if SuckerPunch::Backgroundable.configuration.reload && !(!options[:reload].nil? && options[:reload] == false)
          options[:reload]
        end
        
        def load(receiver)
          receiver.respond_to?(:id) ? receiver.class.find(receiver.id) : receiver
        end
        
        def call(receiver, method, *args)
          if defined?(ActiveRecord)
            begin
              ActiveRecord::Base.connection_pool.with_connection do
                receiver.send(method, *args)
              end
            ensure
              ActiveRecord::Base.connection_handler.clear_active_connections!
            end
          else
            receiver.send(method, *args)
          end
        end
    end
    
    class Job
      include SuckerPunch::Job
      workers SuckerPunch::Backgroundable.configuration.workers
      include CallMethod
    
      def perform(receiver, method, args, options)
        receiver = load(receiver) if instantiate?(options)
        call(receiver, method, *args)
      end
    end
    
    class JobRunner
      include CallMethod
      
      def initialize(receiver, method, args, options)
        @receiver, @method, @args, @options = receiver, method, args, options
      end
      
      def run(seconds = 0)
        if SuckerPunch::Backgroundable.configuration.enabled
          # run as SuckerPunch Job
          if seconds > 0
            Job.perform_in(seconds, @receiver, @method, @args, @options)
          else
            Job.perform_async(@receiver, @method, @args, @options)
          end
        else
          # run without SuckerPunch or Celluloid
          @receiver = load(@receiver) if instantiate?(@options)
          call(@receiver, @method, *@args)
        end
      end
    end

  end
end