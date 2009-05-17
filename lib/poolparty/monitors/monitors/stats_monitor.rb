=begin rdoc
  Stats returns the basic node metrics and checks to see if any actions should be taken based
  on the default expand and contract rules defined in the clouds.rb file.
=end

module Monitors
  
  class Stats < BaseMonitor
    attr_reader :stats, :request
    attr_accessor :response
    
    def initialize(env, o={})
      @env = env
      @request = Rack::Request.new env
      @response = Rack::Response.new
      
      begin
        @cloud = JSON.parse( open('/etc/poolparty/clouds.json' ).read )
      rescue 
        @cloud = ::PoolParty::Default.dsl_options.merge({"options" =>
          {"rules" => {"expand"   => PoolParty::Default.expand_when,
                       "contract" => PoolParty::Default.contract_when
                      }
          }
        })
      end
      # Our cloud.dsl_options.rules looks like
      #  {"expand_when" => "load > 0.9", "contract_when" => "load < 0.4"}
      # We set these as rules on ourselves so we can use aska to parse the rules.
      # Later, we can call vote_rules on ourself and we'll get back Aska::Rule(s)
      # which we'll call valid_rule? for each Rule and return the result
      @cloud["options"]["rules"].each do |name, rul|
        r = Aska::Rule.new(rul)
        rule(name) << r
      end
      # log << "#{::Time.now.strftime("%Y-%m-%d-%H-%M")}, #{stats.to_json}\n"
    end
    
    def get(_data=nil)
      begin
        if !request.params || request.params.empty?
          default_stats
        else
          stats[request.params[0].to_sym] ||= self.send(request.params[0])
          stats[request.params[0].to_sym]
          stats.to_json
        end
      rescue Exception => e
        "Error: #{e}"
      end
    end
    
    def put(data)
      if d = JSON.parse(request.params)
        hsh = d.reject {|ip, _node| ip == my_ip }
        stats.merge!(hsh)
        handle_election
      else
        "boom"
      end
    end
    alias :update :put
    
    protected
    
    def log(log_file_path="/var/log/poolparty/stats_monitor.log")
      if @logfile
        @logfile
      else
        ::File.file? log_file_path
        ::FileUtils.mkdir_p ::File.dirname(log_file_path) unless ::File.directory?(::File.dirname(log_file_path))
        @logfile ||= ::File.open(log_file_path, 'a+')
      end
    end
    
    # Handle the elections
    def handle_election
      # Ballots look like:
      # host => ["contract"]
      candidates = {:expand => 0, :contract => 0}
      candidates.each do |action, ballots|
        stats.each do |ip, node_hsh|
          candidates[action]+=1 if node_hsh["nominations"] && node_hsh["nominations"].include?(action.to_s)
        end
      end
      # TODO: Move?
      # Expand the cloud if 50+% of the votes are for expansion
      # Contract the cloud if 51+% of the votes are for contraction
      # Check to make sure an elected action is not already in progress
      if (candidates[:expand] - candidates[:contract])/stats.keys.size > 0.5
        %x[server-cloud-elections expand] unless elected_action == "expand"
        @elected_action = "expand"
      elsif (candidates[:contract] - candidates[:expand])/stats.keys.size > 0.5
        %x[server-cloud-elections contract] unless elected_action == "contract"
        @elected_action = "contract"
      end      

      reload_data!
      stats[my_ip]["elected_action"] = @elected_action if @elected_action
      log << "#{Time.now.strftime("%Y-%m-%d-%H-%M")}, #{stats.to_json}\n"
      stats.to_json
    end

    def elected_action(_n=nil)
      @elected_action ||= nil
    end

    def rules(_n=nil)
      @rules ||= {}
    end

    def rule(name)
      rules[name] ||= []
    end

    def default_stats
      %w(load nominations).each do |var|
        stats[my_ip][var] ||= self.send(var.to_sym)
      end      
      stats
    end

    def stats(_n=nil)
      @stats ||= {my_ip  => {}}
    end

    def load(_n=nil)
      %x{"uptime"}.split[-3].to_f
    end

    def instances(_n=nil)
      # res = PoolParty::Neighborhoods.load_default.instances
      res ||= %x[server-list-active internal_ip].split("\t")
      res
    end

    def can_expand?(_n=nil)
      instances.size < max_instances
    end

    def can_contract?(_n=nil)
      instances.size > min_instances
    end

    def min_instances(_n=nil)
      (@cloud["options"]["minimum_instances"] || PoolParty::Default.minimum_instances).to_i
    end

    def max_instances(_n=nil)
      (@cloud["options"]["maximum_instances"] || PoolParty::Default.maximum_instances).to_i
    end

    def nominations(_n=nil)
      return ['expand'] if instances.size<min_instances
      load = stats[my_ip]["load"] ||= self.send(:load)
      stats[my_ip]["nominations"] ||= rules.collect do |k,cld_rules|
        t = cld_rules.collect do |r|
          # If the comparison works
          if self.send(r.key.to_sym).to_f.send(r.comparison, r.var.to_f)
            # if we are facing an expansion rule
            if k =~ /expand/
              k if can_expand?
            # if we are facing a contraction rule
            elsif k =~ /contract/
              k if can_contract?
            else
              k
            end
          end
        end.compact
      end.flatten.compact
    end

    #alias to allow access thru http route GET /stats/nominations
    def get_nominations(_nodes=[])
      nominations.to_json
    end
    
    def get_hello(_n=nil)
      'hi there'
    end
    
    def my_ip
      @my_ip ||= ohai["ipaddress"]
    end

    def ohai(_n=nil)
      @ohai ||= JSON.parse(%x[ohai])
    end

    def reload_data!
      @stats[my_ip] = {}
      instances.each {|inst| @stats[inst] = {} }
    end    
    
  end
end