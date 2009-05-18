module PoolParty
  module Pool
    
    def pool(name, &block)
      pools[name] ||= Pool.new(name, &block)
    end
    
    def pools
      $pools ||= {}
    end
    
    def with_pool(pl, opts={}, &block)
      raise CloudNotFoundException.new("Pool not found") unless pl
      pl.dsl_options.merge!(opts) if pl.dsl_options
      pl.run_in_context &block if block
    end
    
    def set_pool_specfile(filename)
      $pool_specfile = filename unless $pool_specfile
    end
    
    def pool_specfile
      $pool_specfile
    end
    
    def reset!
      $pools = $clouds = $plugins = @describe_instances = nil
    end

    class Pool < PoolParty::PoolPartyBaseClass
      include PrettyPrinter
      include CloudResourcer
      include Remote
      
      def initialize(name,&block)
        @pool_name = name
        @pool_name.freeze
        
        ::PoolParty.context_stack.clear
        
        set_pool_specfile get_latest_caller
        setup_defaults

        super(&block)
      end
      
      def self.load_from_file(filename=nil)
        # a = new ::File.basename(filename, ::File.extname(filename))
        File.open(filename, 'r') do |f|
          instance_eval f.read, pool_specfile
        end
        # a
      end
      
      def name(*args)
        @pool_name ||= @pool_name ? @pool_name : (args.empty? ? :default_pool : args.first)
      end

      def parent;nil;end
      
      def setup_defaults        
        PoolParty::Extra::Deployments.include_deployments "#{Dir.pwd}/deployments"
      end
      
      def pool_clouds
        returning Array.new do |arr|
          clouds.each do |name, cl|
            arr << cl if cl.parent.name == self.name
          end
        end
      end
      
      #make my_cloud method available as a Pool class method
      def self.my_cloud
        my_cloud
      end
      
    end #end of Pool class
    
    # Helpers
    def remove_pool(name)
      pools.delete(name) if pools.has_key?(name)
    end
    
    #TODO: move this to Pool.my_cloud class method once dependent code is updated
    # Utility method to be used when on an instance to select a cloud based on keypair name
    # If a pool_spec_file has not already loaded, attempt to load one
    # Useful in server binaries and monitors.
    def my_cloud
      if $pool_specfile.nil?
        if ENV['POOL_SPEC']
          require ENV['POOL_SPEC']
        else
          require '/etc/poolparty/clouds.rb'
        end
      end
      cld_name = ENV['MY_CLOUD']
      if cld_name && clouds[cld_name.to_sym]
        my_cld = clouds[cld_name.to_sym]
      elsif ::File.file?('/etc/poolparty/cloud_name')
        cld_name  = ::File.read('/etc/poolparty/cloud_name')
        my_cld = clouds[cld_name.to_sym]
      else
        raise "Could not find your cloud"
      end
      return my_cld
    end
  
  end
  
end