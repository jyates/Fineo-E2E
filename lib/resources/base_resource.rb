
require 'util/params'

class Resource

  def initialize(source, name)
    @source =  File.join((Params.env_require 'EXT_HOME'), "#{source}")
    @working = File.join(Params::WORKING_DIR, name)
  end

  def unpack
    Dir.mkdir(@working)
    ret = system("tar -xf #{@source} -C #{@working}")
    raise("Could not unpack resource #{@source} => #{@working}") unless ret
    return @working
  end
end
