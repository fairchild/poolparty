=begin rdoc
  MonitorRack is a rack application that maps url requests to method calls on Monitor classes.
=end

require ::File.dirname(__FILE__)+"/../aska"
require ::File.dirname(__FILE__)+"/../lite"
require ::File.dirname(__FILE__)+"/base_monitor"

require 'rubygems'
require 'rack'
require 'json'

# We add an after hook to Rack::Response so that we can initiate a connection after 
# The response is sent back to client.
# PoolParty uses this to update a value, and then pass it on to another node.
class Rack::Response
  %w(close).each do |event|
    module_eval "def before_#{event}_callbacks;@before_#{event}_callbacks ||= [];end"
    module_eval "def after_#{event}_callbacks;@after_#{event}_callbacks ||= [];end"
  end
  
  def close
    before_close_callbacks.flatten.each {|a| a.call }
    body.close if body.respond_to?(:close)
    after_close_callbacks.flatten.each {|a| a.call }
  end
  
end

Dir[::File.dirname(__FILE__)+"/monitors/*"].each {|m| require m}
# PoolParty.require_user_directory "monitors"

module Monitors
  @available_monitors = []
  def available_monitors(monitor_name=nil)
    monitor_name ? @available_monitors.select{|m| m.class == monitor_name} : @available_monitors
  end

  class MonitorRack
    
    
    def call(env)
      @env = env
      @data = env['rack.input'].read rescue nil
      @request = Rack::Request.new env
      @response = Rack::Response.new
      begin
        path_array= path_map(env['REQUEST_PATH']) || []
        verb = env['REQUEST_METHOD'].downcase
        begin
          @response.write(map_to_method(path_array, verb)).to_json
        rescue  Exception => e
          puts  err_msg="Error: #{e}"
          err_msg<<"\n\n------\n ERROR with json method \n--------\n#{map_to_method(path_array, verb).inspect}"
          puts err_msg
          @response.write err_msg
          @response.status = '500'
        end
        if monitor_instance.respond_to? :before_close_callbacks
          @response.before_close_callbacks << monitor_instance.before_close_callbacks
        end
        if monitor_instance.respond_to?(:after_close_callbacks)
          @response.after_close_callbacks << monitor_instance.after_close_callbacks
        end
      # rescue Exception=>e
      #   @response.write e
      #   @response.status = 500
      end
      require 'ruby-debug'; debugger
      
      @response.finish # this is [response.status, response.headers, response.body]
    end
    
    private
    # return an instance of the object matching the first part of the path, if it exists
    def monitor_instance
      return nil if path_map.nil?
      m_instance = Monitors.constants.grep(/#{camelcase(path_map.first)}/).pop
      Monitors.const_get(m_instance).new(env) if m_instance
    end
    
    def env
      @env
    end
    def response
      @response
    end
    def request
      @request
    end
    
    # Split the request path into an array
    def path_map(requested_path=env['REQUEST_PATH'])
      requested_path.split('.')[0].split('/')[1..-1]
    end
  
    # Find class and call method from the pattern /class_name/method/args
    # GET / will return a list of available monitors
    # GET /neighborhood => ::Monitors::Neighboorhood.get
    # POST /neighborhood => ::Monitors::Neighboorhood.post(params)
    # GET /neighborhood/size => ::Monitors::Neighboorhood.get_size
    def map_to_method(path, verb='get')
      if !path or path.empty? or path[0].nil?
        BaseMonitor.available_monitors if verb=='get'
        # response.status ='200'
      else
        raise "#{path[0]} did not map to a Constant" if !monitor_instance
        case path.size
        when 0 # usefull if you want to subclass from MonitorRack
          self.respond_to?(verb.to_sym) ? self.send(verb.to_sym) : response.status='404'
        when 1 # example: /stats
          monitor_instance.send(verb.to_sym, @data)
        when 2 # example: /stats/load
          monitor_instance.send("#{verb}_#{path[1]}".to_sym, @data) rescue monitor_instance.send("#{path[1]}".to_sym, @data)
        else # example: /stats/load/average/5/minutes
          monitor_instance.send("#{verb}_#{path[1]}".to_sym, env['rack.input'].read, *path[2..-1])
        end
      end
    end
    
    def camelcase(str)
      str.gsub(/(^|_|-)(.)/) { $2.upcase }
    end
  
  end
  
end