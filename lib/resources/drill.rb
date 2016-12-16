

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
    return if @started
    zookeeper = @cluster.start
    @server.start(zookeeper, @org)
    @started = true
  end

  def host?
    @server.hostname
  end

  def port?
    @server.port
  end

  def stop
    return unless @started
    @cluster.stop
    @server.stop
  end
end
