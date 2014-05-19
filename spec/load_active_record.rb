# Code taken from http://iain.nl/testing-activerecord-in-isolation

require 'active_record'

db_file = './spec/test.db'
File.delete(db_file) if File.exist?(db_file)
ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: db_file

ActiveRecord::Migration.create_table :test_models do |t|
  t.integer :value
  t.timestamps
end

module ActiveModel::Validations
  # Extension to enhance `should have` on AR Model instances.  Calls
  # model.valid? in order to prepare the object's errors object.
  #
  # You can also use this to specify the content of the error messages.
  #
  # @example
  #
  #     model.should have(:no).errors_on(:attribute)
  #     model.should have(1).error_on(:attribute)
  #     model.should have(n).errors_on(:attribute)
  #
  #     model.errors_on(:attribute).should include("can't be blank")
  def errors_on(attribute)
    self.valid?
    [self.errors[attribute]].flatten.compact
  end
  alias :error_on :errors_on
end
