

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
    @server.start(zookeeper)
  end

  def drill_component?
    new DrillRemote({ "--drill-connection" => @server.connect_string? })
  end

  def stop
    @server.stop
    @cluster.stop
  end
end
