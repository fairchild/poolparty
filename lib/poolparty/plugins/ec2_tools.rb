module PoolParty
  module Plugin
    # Usage: 
    # 
    # ec2_tools :ami_tools_url =>'option if any'  do
    #       api_tools_url
    #       ami_tools_url
    # end
    
    class Ec2Tools < Plugin
      
      default_options :ami_tools_url => "http://s3.amazonaws.com/ec2-downloads/ec2-ami-tools-1.3-26357.zip",
                      :api_tools_url => "http://s3.amazonaws.com/ec2-downloads/ec2-api-tools-1.3-30349.zip",
                      :install_prefix => "/opt/ec2"
      
      # This is called when the plugin is instantiated
      def loaded(opts={}, &block)
        set_vars_from_options opts
        has_package :name=>'unzip'
        has_directory :name => "#{install_prefix}"
        has_exec(
          :name => "download-#{name}", 
          :cwd => install_prefix, 
          :command => "wget #{ami_tools_url} -o ami_tools.zip && unzip ami_tools.zip -d amitools && rsync -a amitools/ #{install_prefix}",
          :if_not => "test -f #{install_prefix}/ami_tools.zip"
        )
        #rsync the ec2 credentials 
         # rsync -av ~/.euca root@192.168.2.194: --stats -e 'ssh -i /Users/mfairchild/.euca/eucalyptus_sample'
        # has_line_in_file :name=>'/root/.bashrc', :content=>'export EC2_HOME=/opt/ec2'
        has_file :name=>'/etc/profile.d/ec2', :content=>"export EC2_HOME=/opt/ec2\nexport PATH=/opt/ec2:$PATH"
      end
      
    end
  end
  
end