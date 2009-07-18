=begin rdoc
  Base
  This handles user interaction, loading the parameters, etc.
=end
require "open-uri"
require "fileutils"
module PoolParty
  class Default
    include Dslify
    
    # def self.options
    default_options(
      :verbose => false,
      :testing => false,
      :minimum_instances => 2,
      :maximum_instances => 5,
      :user => "root", # This should change here
      :keypair_name => nil,
      :base_keypair_path => "#{ENV["HOME"]}/.ec2",
      :base_ssh_path => "#{ENV["HOME"]}/.ssh",
      :tmp_path => "/tmp/poolparty",
      :poolparty_home_path => "#{ENV["HOME"]}/.poolparty",
      :remote_storage_path => "/var/poolparty",
      :remote_gem_path => "/var/poolparty/gems",
      :fileserver_base => "puppet://master/files",
      :base_config_directory => "/etc/poolparty",
      :template_directory => "templates",
      :template_path => "/var/lib/puppet/templates",
      :module_path => "/etc/puppet/modules/poolparty",
      :default_specfile_name => "clouds.rb",
      :properties_hash_filename => "clouds.json",
      :vendor_path => "#{::File.dirname(__FILE__)}/../../../vendor",
      :poolparty_src_path => "#{::File.dirname(__FILE__)}/../../..",
      :port => "80",
      :forwarding_port => "8080",
      :monitor_port => 8081,
      :proxy_mode => "http",
      :butterfly_port => 8642,
      :minimum_runtime  => 3000, #50.minutes in seconds
      :contract_when => "load < 0.25",
      :expand_when => "load > 0.9",
      :ec2_dir => ENV["EC2_HOME"], #TODO: move to ec2 class
      :image_id => nil,
      :access_key => nil,
      :secret_access_key => nil,
      :remoter_base => :ec2,
      :availabilty_zone => 'us-east-1a'
    )
    
    
    # Class methods
    class << self
      def method_missing(m,*a,&block)
        dsl_options.include?(m) ? dsl_options[m] : super
      end
      # # Get the access_key
      #TODO: move the ec2 stuff to ec2.rb
      def access_key
        @access_key ||= load_access_keys_from_environment_var || load_keys_from_file[:access_key]
      end
      def load_access_keys_from_environment_var
         ENV['EC2_ACCESS_KEY'] || ENV['AWS_ACCESS_KEY']
      end
      def secret_access_key
        @secret_access_key ||= load_secret_access_keys_from_environment_var || load_keys_from_file[:secret_access_key]
      end
      def load_secret_access_keys_from_environment_var
        ENV['EC2_SECRET_KEY'] || ENV['AWS_SECRET_ACCESS_KEY']
      end
      def read_keyfile
        open(get_working_key_file_locations).read
      end
      def load_keys_from_file
        @keys ||= get_working_key_file_locations ? YAML::load( read_keyfile ) : {}
      end
      # Store the keys in a yaml format to give the master access
      # So that the master has access to the files
      def store_keys_in_file(f=nil)
        unless access_key.nil? || secret_access_key.nil?
          write_to_file( (f ? f : key_file_locations.first), keys_in_yaml)
        end
      end
      def keys_in_yaml
        YAML::dump({:access_key => access_key, :secret_access_key => secret_access_key})
      end
      def store_keys_in_file_for(obj=nil)
        if obj
          @access_key = obj.access_key
          @secret_access_key = obj.secret_access_key
        end
        store_keys_in_file
      end
      
      def reset!
        @keys = nil
      end
      
      # Get the instance first instance file that exists on the system from the expected places
      # denoted in the local_instances_list_file_locations
      def get_working_key_file_locations
        key_file_locations.reject {|f| f unless ::File.file?(f) }.first
      end
      # Expected places for the instances.list to be located at on the machine
      def key_file_locations
        [
          ".ppkeys",
          "#{Default.base_config_directory}/.ppkeys",
          "#{Default.storage_directory}/ppkeys",
          "#{ENV["HOME"]}/.ssh/ppkeys",
          "#{ENV["HOME"]}/.ssh/.ppkeys",
          "~/.ppkeys",
          "ppkeys"
        ]
      end
      def properties_hash_file
        [
          Default.base_config_directory,
          Dir.pwd
        ].collect do |dir|
          full_dir = ::File.join(dir, Default.properties_hash_filename)
          full_dir if ::File.file?(full_dir)
        end.compact.first || "#{Default.base_config_directory}/#{Default.properties_hash_filename}"
      end
      def storage_directory
        [
            "/var/poolparty"
        ].select do |dir|
          dir if viable_directory?(dir)
        end.first || ::File.join( "/tmp/poolparty/#{name}")
      end
      def logger_location
        [
            "/var/log/poolparty"
        ].select do |dir|
          dir if viable_directory?(dir)
        end.first
      end
      # Assume the logs will be at the pool.log location within the 
      # logger_location set above
      def pool_logger_location
        ::File.join(logger_location, "poolparty.log")
      end
      def custom_monitor_directories
        [
          "/var/poolparty/monitors",
          "/etc/poolparty/monitors",
          "#{Dir.pwd}/monitors"
        ].select {|d| d if viable_directory?(d) }
      end
      
      def custom_modules_directories
        [
          "/var/poolparty/modules",
          "/etc/poolparty/modules",
          "#{Dir.pwd}/modules"
        ].select {|d| d if viable_directory?(d) }
      end
      # Only return true if the directory we are reading is both readable
      # and exists
      def viable_directory?(dir)
        ::File.directory?(dir) && ::File.readable?(dir)
      end
    end
    #end of class methods
    
  end    
end