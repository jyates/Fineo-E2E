
require 'util/params'
require 'util/run'
require 'components/base_component'

# Manages a standalone drill cluster and client server against which you can make SQL requests
class DrillStandalone < BaseComponent

  DRILL_STANDALONE = "io.fineo.read.drill.StandaloneCluster"

  def initialize
    super('DRILL_STANDALONE_HOME')
    @working = setup_dir("drill-standalone")
    @zookeeper = 2181
  end

  def start
    # build the command line to start the process
    jars = aws_jars()
    command = build_java_command(jars, DRILL_STANDALONE, {}, "")

    # spawn a new process for running the local cluster
    @pid = spawn(command, :out => "#{@working}/drill-standalone.log",
      :err => "{@working}/drill-standalone-error.log")
    Process.detach(@pid)
    @zookeeper
  end

  def stop
    run "kill -9 #{@pid}"
  end
end
