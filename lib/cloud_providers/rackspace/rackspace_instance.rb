module CloudProviders
  
  class RackspaceInstance < CloudProviderInstance
      
      default_options(
        {:name        => nil,
         :metadata    => {},
         :addresses   => {:public=>[], :private=>[]},
         :host_id     =>"nil",
         :progress    => nil,
         :flavor_id   => nil,
         :instance_id => nil
         }
       )
      
      #convert rackspace json response format to standard poolparty format
      def self.from_hash(response, &block)
        response.symbolize_keys!(:snake_case)
        response[:internal_ip]  = response[:addresses][:private].first
        response[:public_ip]    = response[:addresses][:public].first
        response[:keypair_name] = response[:metadata][:keypair_name]
        response[:status]       = response[:status].downcase
        response[:instance_id]  = response.delete(:id)
        new(response, &block)
      end
      
      # Terminate the node
      def terminate!
        cloud_provider.api.delete("/servers/#{instance_id}")
      end
      
      # Bootstrap self.  Bootstrap runs as root, even if user is set
      def bootstrap!(force=false)
        #add any CloudProvider bootstrapping specific code before or after super
        super
      end
      
      # Configure the node
      def configure!(opts={})
        #add any CloudProvider configure specific code before or after super
        super
      end
      
    end
end
