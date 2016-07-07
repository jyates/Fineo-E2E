
require 'util/javajars'
require 'util/params'

class BaseComponent

  def initialize(home_env)
    @home = Params.env_require home_env
  end

  def setup_dir(leaf_name)
    dir = File.join(Params::WORKING_DIR, leaf_name)
    Dir.mkdir dir unless Dir.exists? dir
    dir
  end

  def aws_jars
    absolute = File.absolute_path(@home)
    JavaJars.find_aws_jars(absolute)
  end

end
