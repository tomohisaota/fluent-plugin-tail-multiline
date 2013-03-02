module Fluent
  require 'fluent/plugin/in_tail'
  class TailMultilineInput < TailInput
    Plugin.register_input('tail_multiline', self)
    
    config_param :format, :string
    config_param :format_firstline, :string, :default => nil
    config_param :rawdata_key, :string, :default => nil
    
    def initialize
      super
      @locker = Mutex::new
      @logbuf = nil
    end
    
    def configure(conf)
      super
      @regex_firstline = Regexp.new(@format_firstline)
    end
    
    def receive_lines(lines)
      es = MultiEventStream.new
      @locker.synchronize do
        lines.each {|line|
          begin
            if @regex_firstline.match(line)
              time, record = parse_logbuf(@logbuf)
              if time && record
                es.add(time, record)
              end
              @logbuf = line
            else
              @logbuf += line if(@logbuf)
            end
          rescue
            $log.warn line.dump, :error=>$!.to_s
            $log.debug_backtrace
          end
        }
      end
      return if es.empty?
      begin
        Engine.emit_stream(@tag, es)
      rescue
        # ignore errors. Engine shows logs and backtraces.
      end
    end
    
    def shutdown
      super
      flush_logbuf()
    end   

    def flush_logbuf
      time, record = nil,nil
      @locker.synchronize do
        time, record = parse_logbuf(@logbuf)
        @logbuf = nil
      end
      if time && record
        Engine.emit(@tag, time, record)
      end
    end

    def parse_logbuf(buf)
      return nil,nil unless buf
      buf.chomp!
      time, record = parse_line(buf)
      return nil,nil unless time && record
      record[@rawdata_key] = buf if @rawdata_key
      return time, record
    end
    
  end
  
end
