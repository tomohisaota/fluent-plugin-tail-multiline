module Fluent
  require 'fluent/plugin/in_tail'
  class TailMultilineInput < TailInput
    Plugin.register_input('tail_multiline', self)
    
    def initialize
      super
    end
    
    def configure(conf)
      super
    end
    
  end
end
