class ActionController::Responder
  def to_csv
    name = "#{controller.current_client.id}_#{Time.now.to_i}"
    
    return controller.send_data controller.send(:end_of_association_chain).pg_copy_to_string, :filename => "/tmp/#{name}.csv", :type => "application/zip", :disposition => 'inline'
  end
end