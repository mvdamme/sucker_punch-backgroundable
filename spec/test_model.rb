class TestModel < ActiveRecord::Base
  include SuckerPunch::Backgroundable

  @@queue = Queue.new
  
  def self.queue
    @@queue
  end
  
  def self.clear
    @@queue.clear
  end
  
  def copy_value
    @@queue << value
  end

  always_background :copy_value_in_background, :reload => true
  def copy_value_in_background
    sleep(0.4)
    @@queue << value
  end
end