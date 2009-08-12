=begin rdoc
  This is an example CloudProvider to be used as a template for implementing new CloudProviders
=end
require "#{File.dirname(__FILE__)}/rackspace_instance.rb"
require "#{File.dirname(__FILE__)}/rackspace_api.rb"

module CloudProviders
  class Rackspace < CloudProvider
    
    def self.default_api_connection
      @api = RackspaceAPI.new(:username => ENV['RACKSPACE_USERNAME'],
                              :api_key  => ENV['RACKSPACE_API_KEY'])
    end
    
    default_options(
      :name              => nil,
      :flavor_id         => 1,
      :image_id          => 8,  # ubuntu jaunty
      :metadata          => {},
      :personalities     => nil,  #files placed on filesystem at boot
      :rackspace_user    => ENV['RACKSPACE_USERNAME'],
      :rackspace_api_key => ENV['RACKSPACE_API_KEY'],
      :api               => default_api_connection
    )
    
    def initialize(opts={}, &block)
      set_vars_from_options(opts)
      metadata['cloud_name'] = opts[:cloud_name] || cloud.name
      instance_eval(&block) if block
    end
    
    def server_creation_options(opts={})
      {'server'=>{ 'name'          => name,
                   'imageId'       => image_id,
                   'flavorId'      => flavor_id,
                   'metadata'      => {},
                   'personalities' => personality_files
                 }.merge(opts)
      }
    end
    
    # Prepare a list of files that will be injected into the server at boot time.
    # file list is a hash in the format of 
    # {'/path/to/file.txt => "/etc/remote/path"}
    def personality_files(files={})
      injected = files.collect do |local, remote| 
        { 'path'=> remote, 'contents' => Base64.encode64(open(local).read).chomp } 
      end
      injected <<{'path'=>'/root/.ssh/authorized_keys', 
                  'contents' => Base64.encode64(keypair.public_key).chomp } 
      injected
    end
    
    # Launch a new instance. Requires a hash
    def run_instance(o={})
      json = Yajl::Encoder.encode(server_creation_options)
      response = api.post('/servers', :body=>json)
      puts response
      RackspaceInstance.from_hash((response).merge(:cloud=>cloud))
    end
    
    # Terminate an instance by id
    def terminate_instance!(o={})
      raise StandardError.new("you must supply an :instance_id of the instance to terminate") unless o[:instance_id]
       response = api.delete("/servers/#{o[:instance_id]}")
    end
    
    # Describe an instance's status.
    def describe_instance(o={})
      resp = api.get("/servers/#{o[:id]}")['servers'].first
      RackspaceInstance.from_hash((resp).merge(:cloud=>cloud))
    end
    
    # Get instances
    # The instances must return an object responding to each
    # Each yielded object must respond to [:status]
    def describe_instances(o={})
      servers = api.get('/servers/detail')['servers']
      servers.collect{|resp| RackspaceInstance.from_hash((resp).merge(:cloud=>cloud)) }
    end
    
    #TODO: this is simply showing all nodes at the moment. This means you can only have one rackspace cloud in your pool
    def nodes(o={})
      @nodes ||= describe_instances(o)
    end
    
  end
end