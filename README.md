# sucker_punch-backgroundable
[![Build Status](https://travis-ci.org/mvdamme/sucker_punch-backgroundable.png)](https://travis-ci.org/mvdamme/sucker_punch-backgroundable)

This gem allows you to background any method call with [SuckerPunch](https://github.com/brandonhilkert/sucker_punch) without 
having to write a special job class.
It provides the same API as the Backgroundable module from [TorqueBox](http://torquebox.org/), and a large part of the code
comes directly from the TorqueBox project.

## Installation

Add the following to your Gemfile:

```ruby
gem 'sucker_punch-backgroundable'
```

And then execute:

```ruby
bundle install
```

## Usage

Include the `SuckerPunch::Backgroundable` module in your class. Then you can use `always_background :method1, :method2, ...` to
cause the supplied methods to run asynchronously in the background ("fire and forget"). Example:

```ruby
class MyClass
  include SuckerPunch::Backgroundable
  
  always_background :send_email
  def send_email
    # ...
  end
  
  always_background :calculate_statistics
  def self.calculate_statistics
    # ...
  end
end
```

In this example, calls to instance method `send_email` and class method `calculate_statistics` will automatically run in the background:

```ruby
obj = MyClass.new
obj.send_email  # returns immediately, method runs in the background

Myclass.calculate_statistics  # returns immediately, method runs in the background
```

Methods that have not been marked with `always_background` can also be backgrounded when you call them: 

```ruby
class MyClass
  include SuckerPunch::Backgroundable
  
  def notify
    # ...
  end
end

obj = MyClass.new

# This will run in the background (and return immediately)
obj.background.notify

# This will run the method normally (synchronously, returning after the method is finished)
obj.background.notify
```

It is also possible to specify a delay in seconds:

```ruby
# This will return immediately and run the method in the background after a delay of 60 seconds
obj.later(60).notify
```

Both `background` and `later` also work with class methods (e.g. `MyClass.background.my_class_method(argument)`).

### Reloading

When backgrounding an instance method, the method is called on the object, but in a different thread (using SuckerPunch).
If you don't use the object anymore in the current thread, this is ok. If the object is still being used in the current thread,
it may be better to reload it from the data store (assuming a data store backed object) in the background thread to avoid any 
threading issues. The gem can do this automatically, although currently only ActiveRecord is supported:

```ruby
class MyModel < ActiveRecord::Base
  include SuckerPunch::Backgroundable
  
  always_background :send_email, :reload => true
  def send_email
    # ...
  end
end
```

Or, when using `background` or `later`:

```ruby
obj.background(:reload => true).my_instance_method
obj.later(60, :reload => true).my_instance_method
```

It is also possible to specify the `reload` option globally by using an initializer:

```ruby
SuckerPunch::Backgroundable.configure do |config|
  config.reload = true
end
```

## Configuration

Apart from the `reload` option described above, there is two other configuration settings:

```ruby
SuckerPunch::Backgroundable.configure do |config|
  config.reload = true
  config.workers = 4   # default is 2
  config.enabled = true
end
```

The number of workers sets the number of background threads that SuckerPunch will use. The default (and minimum) is 2.

By setting enabled to false, backgrounding is globally disabled, so all methods will be executed synchronously. This
can be useful in tests.

## Usage with ActiveRecord

When using this gem with ActiveRecord models, it is recommended to set the `reload` option to true (see above).
If you want sucker_punch-backgroundable to be available in all models you can  use the following in an initializer:

```ruby
ActiveRecord::Base.send(:include, SuckerPunch::Backgroundable)
```

## Switching from TorqueBox Backgroundable

This gem is completely independent from TorqueBox (or JRuby). But if you are already using TorqueBox Backgroundable, you can switch
to backgrounding with SuckerPunch by a simple change in an initializer:

```ruby
# In config/initializers/active_record_backgroundable.rb, replace
if defined?(TorqueBox::Messaging::Backgroundable) && defined?(ActiveRecord::Base)
  ActiveRecord::Base.send(:include, TorqueBox::Messaging::Backgroundable)
end

# by this:
ActiveRecord::Base.send(:include, SuckerPunch::Backgroundable)
```

Switching from TorqueBox Backgroundable to SuckerPunch will save you RAM (since TorqueBox uses a separate application instance
for Backgroundable), but remember that SuckerPunch jobs are not persisted, so you might lose jobs on a server restart.

## Contributing to sucker_punch-backgroundable
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2014 Michaël Van Damme. See LICENSE.txt for
further details.
