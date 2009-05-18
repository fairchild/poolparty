module PoolParty
  module Verifiers
    
    class VerifierBase
      attr_reader :host
      
      def host=(h=nil)
        @host ||= h
      end
      
      def name
        @name ||= self.class.to_s.top_level_class
      end
    end
    
    def self.inherited(arg)
      base_name = "#{arg}".downcase.top_level_class.to_sym
      (verifiers << base_name) unless verifiers.include?(base_name)
    end
    
  end
end