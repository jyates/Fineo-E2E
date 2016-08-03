
require 'util/params'
require 'util/run'
require 'components/base_component'

# Manages a standalone drill cluster and client server against which you can make SQL requests
class AvaticaServer < BaseComponent

  SERVER = "io.fineo.read.serve.FineoServer"

  def initialize
    super('SERVER_HOME')
    @working = setup_dir("fineo-server")
    @port = 8100
    @hostname = `hostname`.strip
  end

  def start(zookeeper)
    # build the command line to start the process
    jars = aws_jars()
    opts = {
      "--drill-connection" => "jdbc:drill:zk=#{@hostname}:#{zookeeper}",
      "--port" => "#{@port}"
    }
    command = build_java_command(jars, SERVER, opts, "")

    # spawn a new process for running the local cluster
    @pid = spawn(command, :out => "#{@working}/avatica.log",
      :err => "{@working}/avatica-error.log")
    Process.detach(@pid)
  end

  def connect_string?
    "jdbc:avatica:remote:serialization=protobuf;url=#{@hostname}:#{@port}"
  end

  def stop
    run "kill -9 #{@pid}"
  end
end
