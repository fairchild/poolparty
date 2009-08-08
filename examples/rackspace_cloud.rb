$:.unshift File.dirname(__FILE__)+'/../lib/'
require "poolparty"
# $DEBUGGING=true
# $VERBOSE=true
pool :rackspace do
  clouds_dot_rb_file File.expand_path(__FILE__)
    
  cloud :sample do
    instances 1
    os :ubuntu
    
    keypair "eucalyptus_sample"
    using :rackspace do
      image_id 8
    end
    
  end
  
  
end