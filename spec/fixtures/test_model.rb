require 'postgres-copy'

class TestModel < ActiveRecord::Base
  acts_as_copy_target
end
