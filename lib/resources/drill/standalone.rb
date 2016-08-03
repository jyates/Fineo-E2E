
require 'util/run'
require 'util/dirs'
require 'util/params'
require 'util/javajars'

require 'resources/base_resource'

# Manages a standalone drill cluster and client server against which you can make SQL requests
class DrillStandalone < Resource
  include Dirs
  include Run

  DRILL_STANDALONE = "io.fineo.read.drill.StandaloneCluster"

  def initialize
    @home = Params.home('DRILL_STANDALONE_HOME')
    @zookeeper = 2181
    @name = "drill-standalone"
  end

  def start
    @working = setup_dir("drill-standalone")
    # build the command line to start the process
    jars = JavaJars.find_aws_jars(@home)
    command = build_java_command(jars, DRILL_STANDALONE, {}, "")
    spawn_process(command)
    @zookeeper
  end
end
