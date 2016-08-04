
require 'util/run'
require 'util/dirs'
require 'util/params'
require 'util/javajars'

require 'resources/base_resource'

# Manages a standalone drill cluster and client server against which you can make SQL requests
class AvaticaServer < Resource
  include Dirs
  include Run

  SERVER = "io.fineo.read.serve.FineoServer"

  attr_reader :port, :hostname

  def initialize
    @home = Params.home('SERVER_HOME')
    @port = 8100
    @hostname = `hostname`.strip
    @name = "avatica"
  end

  def start(zookeeper, org)
    @working = setup_dir("fineo-server")
    # build the command line to start the process
    jars = JavaJars.find_aws_jars(@home)
    opts = {
      "--drill-connection" => "jdbc:drill:zk=#{@hostname}:#{zookeeper}",
      "--port" => @port,
      "--org-id" => org
    }
    command = build_java_command(jars, SERVER, opts, "")
    spawn_process(command)
  end

  def connect_string?
    "jdbc:avatica:remote:serialization=protobuf;url=#{@hostname}:#{@port}"
  end
end
