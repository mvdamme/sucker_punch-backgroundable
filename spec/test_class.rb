class TestClass
  include SuckerPunch::Backgroundable
  
  @@queue = Queue.new
  
  def self.queue
    @@queue
  end
  
  def self.clear
    @@queue.clear
  end
  
  always_background :always1
  def always1
    add_to_queue
  end
  
  def always2(value)
    add_to_queue(value)
  end
  always_background :always2
  
  def normal(value)
    add_to_queue(value)
  end

  always_background :class_always1
  def self.class_always1
    self.class_add_to_queue
  end
  
  def self.class_always2(value)
    self.class_add_to_queue(value)
  end
  always_background :class_always2
  
  def self.class_normal(value)
    self.class_add_to_queue(value)
  end

  private
  
    def add_to_queue(value = 1)
      sleep(0.4)
      @@queue << value
    end

    def self.class_add_to_queue(value = 1)
      sleep(0.4)
      @@queue << value
    end
    
end