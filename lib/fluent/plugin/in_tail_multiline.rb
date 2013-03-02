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
    
    def receive_lines(lines)
      es = MultiEventStream.new
      lines.each {|line|
        begin
          line.chomp!  # remove \n
          time, record = parse_line(line)
          if time && record
            es.add(time, record)
          end
        rescue
          $log.warn line.dump, :error=>$!.to_s
          $log.debug_backtrace
        end
      }
      unless es.empty?
        begin
          Engine.emit_stream(@tag, es)
        rescue
          # ignore errors. Engine shows logs and backtraces.
        end
      end
    end
  end
end
