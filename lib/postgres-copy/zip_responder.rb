
Mime::Type.register 'application/zip', :zip

class ActionController::Responder
  def to_zip
    name = "#{controller.current_client.id}_#{Time.now.to_i}"
    controller.send(:end_of_association_chain).pg_copy_to "/tmp/#{name}.csv"
    Dir.chdir('/tmp') do
     `zip #{name} #{name}.csv`
     zip = "#{name}.zip"
     return controller.send_file zip, :filename => zip, :type => "application/zip", :disposition => 'inline'
    end
  end
end
