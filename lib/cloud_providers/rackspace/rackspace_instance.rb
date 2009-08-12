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
      
      def host
        public_ip
      end
      
      # Set the keypair, or retreive it from the cloud if not already set
      def keypair(n=nil)
        if n
          dsl_options[:keypair] = n
        elsif cloud
          dsl_options[:keypair] ||= cloud.keypair
        else
          dsl_options[:keypair]
        end
      end
      
      def inspect
        keys=[:status, :host_id, :keypair_name, :metadata, :internal_ip, :dns_name, :launch_time, :instance_id, :flavor_id, :cloud_name, :progress, :name, :public_ip, :addresses, :image_id]
        "#{self.class} #{self.object_id}: #{keys.inject({}){|s,k| s[k]=self.send(k);s}.inspect}"
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
      
      def cloud_provider
        cloud.cloud_provider
        
      end
      
    end
end
