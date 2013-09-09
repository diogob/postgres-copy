require 'postgres-copy'

class ExtraField < ActiveRecord::Base
  acts_as_copy_target
end

