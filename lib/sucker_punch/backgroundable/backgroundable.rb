# The majority of this file (> 95%) was copied from the Backgroundable module in Torquebox
# (see https://github.com/torquebox/torquebox/blob/master/gems/messaging/lib/torquebox/messaging/backgroundable.rb).
# The code was slightly adapted so it works with Sucker Punch instead of Torquebox messaging.

module SuckerPunch

  # Backgroundable provides mechanism for executing an object's
  # methods asynchronously.
  module Backgroundable

    def self.included(base)
      base.extend(BackgroundableClassMethods)
    end

    # Allows you to background any method that has not been marked
    # as a backgrounded method via {BackgroundableClassMethods#always_background}.
    def background(options = { })
      BackgroundProxy.new(self, options)
    end

    # Allows you to background any method that has not been marked
    # as a backgrounded method via {BackgroundableClassMethods#always_background}.
    # The method will not be executed immediately, but only after 'seconds' seconds.
    def later(seconds, options = { })
      BackgroundProxy.new(self, options, seconds)
    end

    module BackgroundableClassMethods

      # Marks methods to always be backgrounded. Takes one or more
      # method symbols, and an optional options hash as the final
      # argument. 
      def always_background(*methods)
        options = methods.last.is_a?(Hash) ? methods.pop : {}
        @__backgroundable_methods ||= {}

        methods.each do |method|
          method = method.to_s
          if !@__backgroundable_methods[method]
            @__backgroundable_methods[method] ||= { }
            @__backgroundable_methods[method][:options] = options
            if Util.singleton_methods_include?(self, method) ||
                Util.instance_methods_include?(self, method)
              __enable_backgrounding(method)
            end
          end
        end
      end

      # Allows you to background any method that has not been marked
      # as a backgrounded method via {BackgroundableClassMethods#always_background}.
      def background(options = { })
        BackgroundProxy.new(self, options)
      end

      # Allows you to background any method that has not been marked
      # as a backgrounded method via {BackgroundableClassMethods#always_background}.
      # The method will not be executed immediately, but only after 'seconds' seconds.
      def later(seconds, options = { })
        BackgroundProxy.new(self, options, seconds)
      end

      # @api private
      def method_added(method)
        super
        __method_added(method)
      end

      # @api private
      def singleton_method_added(method)
        super
        __method_added(method)
      end

      private
      
      def __method_added(method)
        method = method.to_s
        if @__backgroundable_methods &&
            @__backgroundable_methods[method] &&
            !@__backgroundable_methods[method][:backgrounding]
          __enable_backgrounding(method)
        end
      end

      def __enable_backgrounding(method)
        singleton_method = Util.singleton_methods_include?(self, method)
        singleton = (class << self; self; end)

        if singleton_method

          SuckerPunch.logger.
            warn("always_background called for :#{method}, but :#{method} " +
                 "exists as both a class and instance method. Only the " +
                 "class method will be backgrounded.") if Util.instance_methods_include?(self, method)

          privatize = Util.private_singleton_methods_include?(self, method)
          protect = Util.protected_singleton_methods_include?(self, method) unless privatize
        else
          privatize = Util.private_instance_methods_include?(self, method)
          protect = Util.protected_instance_methods_include?(self, method) unless privatize
        end

        async_method = "__async_#{method}"
        sync_method = "__sync_#{method}"

        @__backgroundable_methods[method][:backgrounding] = true
        options = @__backgroundable_methods[method][:options]

        (singleton_method ? singleton : self).class_eval do
          define_method async_method do |*args|
            # run sucker punch job asynchronously
            Job.new.async.perform(self, sync_method, args, options)
          end
        end
        
        code = singleton_method ? "class << self" : ""
        code << %Q{
          alias_method :#{sync_method}, :#{method}
          alias_method :#{method}, :#{async_method}
        }
        code << %Q{
          #{privatize ? "private" : "protected"} :#{method}, :#{sync_method}, :#{async_method}
        } if privatize || protect
        code << "end" if singleton_method

        class_eval code
      ensure
        @__backgroundable_methods[method][:backgrounding] = nil
      end

    end

    # @api private
    class BackgroundProxy
      def initialize(receiver, options, seconds = 0)
        @receiver = receiver
        @options = options
        @seconds = seconds
      end

      def method_missing(method, *args, &block)
        @receiver.method_missing(method, *args, &block) unless @receiver.respond_to?(method)
        raise ArgumentError.new("Backgrounding a method with a block argument is not supported.") if block_given?
        if @seconds > 0
          Job.new.async.later(@seconds, @receiver, method, args, @options)
        else
          Job.new.async.perform(@receiver, method, args, @options)
        end
      end
    end
    
  end

end