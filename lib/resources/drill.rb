

require 'components/drill/remote'

require 'resources/drill/base'
require 'resources/drill/standalone'
require 'resources/drill/avatica_server'
require 'resources/drill/read_proxy'

class DrillResource < BaseDrill

  def initialize
    @cluster = DrillStandalone.new
    @server = AvaticaServer.new
    @proxy = ReadProxy.new
  end

  def start
    return if @started
    zookeeper = @cluster.start
    @server.start(zookeeper, @org)
    @proxy.start(@server.port)
    @started = true
  end

  def host?
    @server.hostname
  end

  def port?
    @server.port
  end

  def proxy_host?
    @proxy.hostname
  end

  def proxy_port?
    @proxy.port
  end

  def stop
    return unless @started
    @cluster.stop
    @server.stop
    @proxy.stop
  end
end
