
require 'resources/drill/standalone.rb'
require 'resources/drill/avatica_server.rb'

class DrillResource

  def initialize
    @cluster = DrillStandalone.new
    @server = AvaticaServer.new
  end

  def start
    zookeeper = @cluster.start
    @server.start(zookeeper)
  end

  def stop
    @server.stop
    @cluster.stop
  end
end
