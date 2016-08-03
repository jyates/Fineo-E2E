
require 'util/run'
require 'util/javajars'
require 'util/params'
require 'util/dirs'

class BaseComponent
  include Run
  include Dirs

  def initialize(env)
    @home = Params.home(env)
  end

  def aws_jars
    JavaJars.find_aws_jars(@home)
  end

end
