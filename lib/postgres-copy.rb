require 'rubygems'
require 'active_support'

ActiveSupport.on_load :active_record do
  require "postgres-copy/acts_as_copy_target"
end

ActiveSupport.on_load :action_controller do
  require "postgres-copy/csv_responder"
end
