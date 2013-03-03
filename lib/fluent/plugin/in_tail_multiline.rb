module Fluent
  require 'fluent/plugin/in_tail'
  class TailMultilineInput < TailInput
    Plugin.register_input('tail_multiline', self)
    
    config_param :format, :string
    config_param :format_firstline, :string, :default => nil
    config_param :rawdata_key, :string, :default => nil
    config_param :auto_flush_sec, :integer, :default => 1
    
    def initialize
      super
      @locker = Monitor.new
      @logbuf = nil
      @logbuf_flusher = CallLater::new
    end
    
    def configure(conf)
      super
      if @format_firstline
        # Use custom matcher for 1st line
        if @format_firstline[0] == '/' && @format_firstline[@format_firstline.length-1] == '/'
          regEx = Regexp.new(@format_firstline[1..-2])
          @regex_firstline = Proc.new{ |line|
            regEx.match(line)
          }
        else
          raise Fluent::ConfigError.new("format_firstline format error")
        end
      else
        # Use in-tail matcher
        @regex_firstline = Proc.new{ |line|
          time,record = @parser.parse(line)
          time && record
        }
      end
    end
    
    def receive_lines(lines)
      @logbuf_flusher.cancel()
      es = MultiEventStream.new
      @locker.synchronize do
        lines.each {|line|
          begin
            if @regex_firstline.call(line)
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
      unless es.empty?
        begin
          Engine.emit_stream(@tag, es)
        rescue
          # ignore errors. Engine shows logs and backtraces.
        end
      end
      @logbuf_flusher.call_later(@auto_flush_sec) do
        flush_logbuf()
      end
    end
    
    def shutdown
      super
      flush_logbuf()
      @logbuf_flusher.shutdown()
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
  
  class CallLater 
    def initialize
      @locker = Monitor::new
      @thread = Thread.new(&method(:run))
      initExecBlock()
    end
    
    def call_later(delay,&block)
      @locker.synchronize do
        @exec_time = Engine.now + delay
        @exec_block = block
      end
      @thread.run
    end
    
    def run
      @running = true
      while true
        sleepSec = -1
        @locker.synchronize do
          now = Engine.now
          if @exec_block && @exec_time <= now
            @exec_block.call()
            initExecBlock()
          end          
          return unless @running
          unless(@exec_time == -1)
            sleepSec = @exec_time - now 
          end
        end
        if (sleepSec == -1)
          sleep()
        else
          sleep(sleepSec)
        end
      end
    rescue => e
      puts e
    end
    
    def cancel()
      initExecBlock()
    end

    def shutdown()
      @locker.synchronize do
        @running = false
      end
      if(@thread)
        @thread.run
        @thread.join
        @thread = nil
      end
    end    
    
    private 

    def initExecBlock()
      @locker.synchronize do
        @exec_time = -1
        @exec_block = nil
      end
    end
    
  end
end
