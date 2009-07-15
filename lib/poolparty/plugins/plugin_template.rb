module PoolParty
  module Plugin
    # Usage: 
    # 
    # plugin_name :optional=>'option if any'  do
    #   extras :cli, :pspell, :mysql
    # end
    
    class EmptyPlugin < Plugin
      
      # This is called when the plugin is instantiated
      def loaded(opts={}, &block)
      end
      
    end
  end
  
end