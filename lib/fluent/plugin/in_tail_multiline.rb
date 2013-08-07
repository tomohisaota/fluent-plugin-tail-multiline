module Fluent
  require 'fluent/plugin/in_tail'
  class TailMultilineInput < TailInput
    
    class MultilineTextParser < TextParser
      def configure(conf, required=true)
        format = conf['format']
        if format == nil
          raise ConfigError, "'format' parameter is required"
        elsif format[0] != ?/ || format[format.length-1] != ?/ 
          raise ConfigError, "'format' should be RegEx. Template is not supported in multiline mode"
        end
        
        begin
          @regex = Regexp.new(format[1..-2],Regexp::MULTILINE)
          if @regex.named_captures.empty?
            raise "No named captures"
          end
        rescue
          raise ConfigError, "Invalid regexp in format '#{format[1..-2]}': #{$!}"
        end

        @parser = RegexpParser.new(@regex)

        if @parser.respond_to?(:configure)
          @parser.configure(conf)
        end

        format_firstline = conf['format_firstline']
        if format_firstline
          # Use custom matcher for 1st line
          if format_firstline[0] == '/' && format_firstline[format_firstline.length-1] == '/'
            @regex = Regexp.new(format_firstline[1..-2])
          else
            raise ConfigError, "Invalid regexp in format_firstline '#{format_firstline[1..-2]}': #{$!}"
          end
        end

        return true
      end
      
      def match_firstline(text)
        @regex.match(text)
      end
    end
    
    Plugin.register_input('tail_multiline', self)

    FORMAT_MAX_NUM = 20
    
    config_param :format, :string
    config_param :format_firstline, :string, :default => nil
    config_param :rawdata_key, :string, :default => nil
    config_param :auto_flush_sec, :integer, :default => 1
    config_param :read_newfile_from_head, :bool, :default => false
    (1..FORMAT_MAX_NUM).each do |i|
      config_param "format#{i}".to_sym, :string, :default => nil
    end
    
    def initialize
      super
      @locker = Monitor.new
      @logbuf = nil
      @logbuf_flusher = CallLater::new
    end

    def configure(conf)
      if conf['format'].nil?
        invalids = conf.keys.select{|k| k =~ /^format(\d+)$/ and not (1..FORMAT_MAX_NUM).include?($1.to_i)}
        if invalids.size > 0
          raise ConfigError, "invalid number formats (valid format number:1-#{FORMAT_MAX_NUM}):" + invalids.join(",")
        end
        format_index_list = conf.keys.select{|s| s =~ /^format\d+$/}.map{|v| (/^format(\d+)$/.match(v))[1].to_i}
        if (1..format_index_list.max).map{|i| conf["format#{i}"]}.include?(nil)
          raise Fluent::ConfigError, "jump of format index found"
        end
        formats = (1..FORMAT_MAX_NUM).map {|i|
          conf["format#{i}"]
        }.delete_if {|format|
          format.nil?
        }.map {|format|
          format[1..-2]
        }.join
        conf['format'] = '/' + formats + '/'
      end
      super
      if read_newfile_from_head and @pf
        # Tread new file as rotated file
        # Use temp file inode number as previos logfile
        @paths.map {|path|
          pe = @pf[path]
          if pe.read_inode == 0
            require 'tempfile'
            tmpfile = Tempfile.new('gettempinode')
            pe.update(File.stat(tmpfile).ino, 0)
            tmpfile.unlink
          end
        }
      end
    end
    
    def configure_parser(conf)
      @parser = MultilineTextParser.new
      @parser.configure(conf)
    end
    
    def receive_lines(lines)
      @logbuf_flusher.cancel()
      es = MultiEventStream.new
      @locker.synchronize do
        lines.each {|line|
            if @parser.match_firstline(line)
              time, record = parse_logbuf(@logbuf)
              if time && record
                es.add(time, record)
              end
              @logbuf = line
            else
              @logbuf += line if(@logbuf)
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
      begin
        time, record = @parser.parse(buf)
      rescue
        $log.warn buf.dump, :error=>$!.to_s
        $log.debug_backtrace
      end
      return nil,nil unless time && record
      record[@rawdata_key] = buf if @rawdata_key
      return time, record
    end
    
  end
  
  class CallLater 
    def initialize
      @locker = Monitor::new
      initExecBlock()
      @thread = Thread.new(&method(:run))
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
