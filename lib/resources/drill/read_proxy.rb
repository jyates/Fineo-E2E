
require 'util/run'
require 'util/dirs'
require 'util/params'
require 'util/javajars'

require 'resources/base_resource'

# Manages a standalone drill cluster and client server against which you can make SQL requests
class ReadProxy < Resource
  include Dirs
  include Run

  # no name necessary to run the process
  PROXY_STANDALONE = ""

  attr_reader :port, :hostname

  def initialize
    @home = Params.home('PROXY_HOME')
    @name = "readerator-proxy"
    @hostname = `hostname`.strip
    @port = 8200
  end

  def start(port)
    @working = setup_dir("readerator-proxy")
    # create the yaml file
    config = File.join(@working, "config.yml")
    File.open(config, "w") { |file|
      file.puts("jdbcUrl: jdbc:fineo:url=http://#{@hostname}:#{port}")
      file.puts("server:")
      file.puts("  applicationConnectors:")
      file.puts("    - type: http")
      file.puts("      port: #{@port}")
    }

    # build the command line to start the process
    jars = JavaJars.find_aws_jars(@home)
    command = build_java_jar_command(jars[0], {}, PROXY_STANDALONE, {}, "server", {"#{config}"=>""})
    spawn_process(command)
  end
end
