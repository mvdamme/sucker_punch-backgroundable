require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/test_class')

describe "sucker_punch-backgroundable" do
  before :each do
    @obj = TestClass.new
    TestClass.clear
  end
 
  context 'instance methods' do
    it "backgrounds instance methods declared after :always_background" do
      @obj.always1
      check_queue(1)
    end
    
    it "backgrounds instance methods declared before :always_background" do
      @obj.always2(100)
      check_queue(100)
    end
    
    it "allows backgrounding of instance methods not declared as :always_background" do
      @obj.background.normal(200)
      check_queue(200)
    end

    it "allows running instance methods with a specified delay" do
      @obj.later(2).normal(200) # run after 2 seconds
      check_queue(200, 2.2)
    end

    it "allows running instance methods with a specified delay, even when they are declared as :always_background" do
      @obj.later(2).always1 # run after 2 seconds
      check_queue(1, 2.2)
    end
  end 
  
  context 'class methods' do
    it "backgrounds class methods declared after :always_background" do
      TestClass.class_always1
      check_queue(1)
    end
    
    it "backgrounds class methods declared before :always_background" do
      TestClass.class_always2(100)
      check_queue(100)
    end
    
    it "allows backgrounding of class methods not declared as :always_background" do
      TestClass.background.class_normal(200)
      check_queue(200)
    end

    it "allows running class methods with a specified delay" do
      TestClass.later(2).class_normal(200) # run after 2 seconds
      check_queue(200, 2.2)
    end

    it "allows running class methods with a specified delay, even when they are declared as :always_bacground" do
      TestClass.later(2).class_always1 # run after 2 seconds
      check_queue(1, 2.2)
    end
  end 
  
  context 'singleton methods' do
    before :each do 
      def @obj.my_singleton(value)
        add_to_queue(value + 1)
      end
    end
    
    it "allows backgrounding of singleton methods" do
      @obj.background.my_singleton(200)
      check_queue(201)
    end

    it "allows running singleton methods with a specified delay" do
      @obj.later(2).my_singleton(200) # run after 2 seconds
      check_queue(201, 2.2)
    end
  end
  
  def check_queue(value, wait_before = 0.2, wait_after = 0.3)
    sleep( wait_before )
    expect( TestClass.queue.length ).to eq(0)
    sleep( wait_after )
    expect( TestClass.queue.length ).to eq(1)
    expect( TestClass.queue.pop ).to eq(value)
  end
  
  context 'reloading' do
    before do
      require File.expand_path(File.dirname(__FILE__) + '/load_active_record')
      require File.expand_path(File.dirname(__FILE__) + '/test_model')
    end
    
    before :each do
      @model = TestModel.create(:value => 5)
    end

    after :each do
      TestModel.delete_all
    end

    it "fully reloads objects when :reload option is true" do
      @model.later(0.4, :reload => true).copy_value
      @model.value += 1 # change object
      sleep(0.5)
      expect( TestModel.queue.pop ).to eq(5)
    end

    it "doesn't reload objects when :reload option is false" do
      @model.later(0.4).copy_value # :reload defaults to false
      @model.value += 1 # change object
      sleep(0.5)
      expect( TestModel.queue.pop ).to eq(6)
    end

    it "respects :reload => true as option to :always_background" do
      @model.copy_value_in_background
      @model.value += 1 # change object
      sleep(0.5)
      expect( TestModel.queue.pop ).to eq(5)
    end

    context 'global reload option' do
      before do
        SuckerPunch::Backgroundable.configure do |config|
          config.reload = true
        end
      end
      
      after do
        SuckerPunch::Backgroundable.configure do |config|
          config.reload = false
        end
      end
      
      it "honors when global reload is set to true" do
        @model.later(0.4).copy_value
        @model.value += 1 # change object
        sleep(0.5)
        expect( TestModel.queue.pop ).to eq(5)
      end

      it "honors :reload => false even when when global reload is set to true" do
        @model.later(0.4, :reload => false).copy_value
        @model.value += 1 # change object
        sleep(0.5)
        expect( TestModel.queue.pop ).to eq(6)
      end

      it "ignores :reload for class methods" do
        TestModel.class_always
        sleep(0.5)
        expect( TestModel.queue.pop ).to eq(7)
      end

    end
  end
  
  context 'enable / disable' do
    before do
      SuckerPunch::Backgroundable.configure do |config|
        config.enabled = false
      end
      @obj = TestClass.new
      TestClass.clear
    end

    it "respects enabled => false for methods marked as :always_background" do
      @obj.always1
      expect( TestClass.queue.length ).to eq(1)
      expect( TestClass.queue.pop ).to eq(1)
    end
    
    it "respects enabled => false for calls to 'background'" do
      @obj.background.normal(6)
      expect( TestClass.queue.length ).to eq(1)
      expect( TestClass.queue.pop ).to eq(6)
    end

    it "respects enabled => false for calls to 'later'" do
      @obj.later(10).normal(6)
      expect( TestClass.queue.length ).to eq(1)
      expect( TestClass.queue.pop ).to eq(6)
    end

    it "respects enabled => false for methods marked as :always_background (with reloading)" do
      require File.expand_path(File.dirname(__FILE__) + '/load_active_record')
      require File.expand_path(File.dirname(__FILE__) + '/test_model')
      @model = TestModel.create(:value => 5)
      @model.copy_value_in_background
      expect( TestModel.queue.pop ).to eq(5)
    end
    
  end

end
