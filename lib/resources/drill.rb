

require 'components/drill/remote'

require 'resources/drill/base'
require 'resources/drill/standalone'
require 'resources/drill/avatica_server'

class DrillResource < BaseDrill

  def initialize
    @cluster = DrillStandalone.new
    @server = AvaticaServer.new
  end

  def start
    zookeeper = @cluster.start
    @server.start(zookeeper, @org)
  end

  def drill_component?
    DrillRemote.new({ "--jdbc-host" => @server.hostname,
                      "--jdbc-port" => @server.port})
  end

  def stop
    @cluster.stop
    @server.stop
  end
end
