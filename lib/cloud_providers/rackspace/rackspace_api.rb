require 'httparty'
require 'yajl'

module CloudProviders

  class RackspaceAPI
    include HTTParty
     format :json
  
    attr_reader :auth
    def initialize(opts={})
      opts[:username] ||= ENV['RACKSPACE_USERNAME']
      opts[:api_key]  ||= ENV['RACKSPACE_API_KEY']
      # if @auth && @auth['x-auth-token'] #&& (Time.now - Time.parse(@rs.auth['date'].first))>0
      @auth = authenticate(:username=>opts[:username], :api_key=>opts[:api_key])
      self.class.headers('X-Auth-Token' => @auth['x-auth-token'].first,
                          'Content-Type' => 'application/json',
                          'Accept' => 'application/json'
                        )
      self.class.base_uri @auth['x-server-management-url'].first
      
    end
    
    # authtenticate and set the auth_token and api base url
    def authenticate(opts={})
      @auth=self.class.get('https://auth.api.rackspacecloud.com/v1.0', 
                   :headers=>{'X-Auth-Key' => opts[:api_key],
                              'X-Auth-User'=> opts[:username]}
                  ).headers
      raise "Authentication Failure" unless @auth['x-auth-token']
      @auth
    end
    
    def get(path, opts={});    self.class.get(path, opts)   ;end
    def post(path, opts={});   self.class.post path, opts   ;end
    def put(path, opts={});    self.class.put(path, opts)   ;end
    def delete(path, opts={}); self.class.delete(path, opts);end
    
    # @get_methods = %w(limits flavors servers images shared_ip_groups backup_schedules)
    # @get_methods.each do |m|
    #   # next if self.method_defined? m
    #   gm=<<-EOS
    #     def #{m}(id=nil, opts={}); self.class.get("/#{m}/#{id}", opts) ;end
    #     def #{m}(opts={}); self.class.get("/#{m}/details", opts) ;end
    #   EOS
    #   p gm
    #   class_eval gm
    # end
    
    # def method_missing(m, *args, &block)
    #   p ["/#{m.to_s}", args]
    #   self.class.get "/#{m.to_s}", *args, &block
    # end
  
  end


end