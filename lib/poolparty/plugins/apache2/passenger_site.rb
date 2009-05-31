require File.dirname(__FILE__)+'/apache'
module PoolParty
  module Plugin
    # Usage:
    #
    # passengersite do
    # end
    class PassengerSite < Apache
      
      default_options(
        :dir            => "/var/www",
        :appended_path  => nil,
        :owner          => 'www-data', 
        :mode           =>'0744',
        :enviornment    => 'production'
      )
      
      def loaded(opts={}, prnt=nil)
        enable_passenger
        require 'ruby-debug'; debugger
        'hi'
        port "80" unless self.port
        
        has_directory(:name => dir,                      :owner => www_user, :mode => '0744')
        has_directory(:name => "#{site_directory}",      :owner => www_user, :mode => '0744')
        has_directory(:name => "#{site_directory}/logs", :owner => www_user, :mode => '0744')
        
        if opts[:with_deployment_directories]
          has_site_directory :name => "shared"
          has_site_directory :name => "shared/public"
          has_site_directory :name => "shared/config"
          has_site_directory :name => "shared/log"
          has_site_directory :name => "releases"
          if !::File.exists?(#{dir}/#{name}/current)
          
          # setup an initial symlink so apache will start even if there have not been any deploys yet
            has_site_directory(:name => "releases/initial/public")
            #FIXME  the following line is chef specific.  It will fail with puppet
            has_symlink(:target_file => "#{dir}/#{name}/current", 
                        :to => "#{dir}/#{name}/releases/initial")
          end
          log_dir = "#{site_directory}/shared/log"
          appended_path "current"
          
        else
          log_dir = "#{site_directory}/log"
        end
        
        passenger_entry <<-EOE
  <VirtualHost *:#{port}>
      ServerName #{name}
      DocumentRoot #{site_directory}/public
      RailsEnv #{enviornment}
      ErrorLog #{log_dir}/error_log
      CustomLog #{log_dir}/access_log common
  </VirtualHost>
        EOE
        
        # has_directory(:name => "/var/www")
        # has_directory(:name => "/var/www/#{name}")
        # has_directory(:name => "/var/www/#{name}/log")
        parent.install_site(name, :no_file => true) # we already created the file with #passenger_entry
      end
      
      def passenger_entry(file)
        if ::File.file?(file)
          has_file({:name => "/etc/apache2/sites-available/#{name}", :template => file})
        else
          has_file({:content => file, :name => "/etc/apache2/sites-available/#{name}" })
        end
      end
      
      def has_site_directory(opts={})
        has_directory(:name   => "#{site_directory}/#{opts.delete(:name)}", 
                      :owner  => www_user, 
                      :mode   =>'0744'
                      ).merge(opts)
      end
      
      def site_directory
        "#{dir}/#{name}%s" % [appended_path ? "/" + appended_path : ""]
      end
    end
    
  end
  
end