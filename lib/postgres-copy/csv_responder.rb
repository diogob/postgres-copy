class ActionController::Responder
  def to_csv
    name = "#{controller.resource.class.name.downcase}_#{Time.now.to_i}"
    
    return controller.send_data controller.send(:end_of_association_chain).pg_copy_to_string, :filename => "/tmp/#{name}.csv", :type => "text/csv", :disposition => 'inline'
  end
end
