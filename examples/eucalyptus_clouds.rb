# Poolparty spec

pool :eucalyptus do
    
  cloud :sample do
    instances 1
    keypair "eucalyptus_sample"
    has_file "/etc/motd", :content => "Simple"
    # before :bootstrap do
    #   netssh(["uptime"])
    # end
    using :ec2 do
      image_id 'emi-39CA160F'
    end
  end
  
end
