require 'postgres-copy'

class TestExtendedModel < ActiveRecord::Base
  acts_as_copy_target
end
