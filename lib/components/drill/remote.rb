
require 'components/drill/bootstrap'
require 'components/drill/standalone'
require 'components/drill/drill_component'
require 'util/dirs'

class DrillRemote
  include DrillComponent
  include Dirs

  HOME = 'DRILL_REMOTE_READ_HOME'

  def initialize(cluster, source)
    @source = source
    @cluster = cluster
    @bootstrap = Bootstrap.new(HOME, cluster)
    @read = Standalone.new(HOME, cluster, source)
    @supports_proxy = true
  end

  def getTableName(org, metric)
    return metric
  end

  def bootstrap(context, log=false)
    @bootstrap.exec(context)
    puts "   Waiting a litte bit in hopes that read will work more often..." if log
    sleep(5)
  end

  def read_internal(context, log=false)
    bootstrap(context, log)
    @read.exec(context)
  end
end
