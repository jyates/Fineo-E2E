
require 'util/params'

class Resource

  def initialize(source, name)
    @name = name
    @source =  File.join((Params.env_require 'EXT_HOME'), "#{source}")
    @working = File.join(Params::WORKING_DIR, name)
  end

  def unpack
    puts "Unpacking #{@source} into #{@working}"
    Dir.mkdir(@working)
    ret = system("tar -xf #{@source} -C #{@working}")
    raise("Could not unpack resource #{@source} => #{@working}") unless ret
    return @working
  end

  def spawn_process(cmd, verify=Proc.new {|o,e| true})
    out = "#{@working}/#{@name}.log"
    err = "#{@working}/#{@name}-error.log"
    File.open("#{out}-start.txt", "w"){|file|
      file.write(cmd)
    }
    @pid = spawn("#{cmd}", :out => "#{out}", :err => "#{err}")
    Process.detach(@pid)
    unless verify.call(out, err)
      raise "#{@name} didn't start correctly! See #{err} for more info"
    end

    @started = true
    puts "(#{@pid}) Running #{@name} from #{@working}. Output/errors is logged to #{@working}"
  end

  def stop
    return unless @started
    begin
      Process.kill(0, @pid)
      puts "Stopping local #{@name}(#{@pid})"
      system("kill -9 #{@pid}")
    rescue
      puts "Service (#{@pid}) #{@name} was prematurely killed! Check logs for more info."
    end
  end

  def log?
    " >> #{@working}/out.log 2>> #{@working}/error.log"
  end
end
