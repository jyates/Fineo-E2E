
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
    out = "#{@working}/#{@name}.out"
    err = "#{@working}/#{@name}.err"
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
    puts "Stopping local #{@name}(#{@pid})"
    system("kill -9 #{@pid}")
  end

  def log?
    " >> #{@working}/out.log 2>> #{@working}/error.log"
  end
end
