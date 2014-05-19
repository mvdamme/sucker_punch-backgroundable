# This code was copied from the Backgroundable module in Torquebox
# (see https://github.com/torquebox/torquebox/blob/master/gems/messaging/lib/torquebox/messaging/backgroundable.rb).

module SuckerPunch

  module Backgroundable

    module Util

      class << self
        def singleton_methods_include?(klass, method)
          methods_include?(klass.singleton_methods, method) ||
            private_singleton_methods_include?(klass, method)
        end

        def private_singleton_methods_include?(klass, method)
          methods_include?(klass.private_methods, method)
        end

        def protected_singleton_methods_include?(klass, method)
          methods_include?(klass.protected_methods, method)
        end

        def instance_methods_include?(klass, method)
          methods_include?(klass.instance_methods, method) ||
            private_instance_methods_include?(klass, method)
        end

        def private_instance_methods_include?(klass, method)
          methods_include?(klass.private_instance_methods, method)
        end

        def protected_instance_methods_include?(klass, method)
          methods_include?(klass.protected_instance_methods, method)
        end

        def methods_include?(methods, method)
          method = (RUBY_VERSION =~ /^1\.8\./ ? method.to_s : method.to_sym)
          methods.include?(method)
        end
      end
      
    end

  end

end