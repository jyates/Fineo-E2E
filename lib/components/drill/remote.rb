
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
    @bootstrap = Bootstrap.new(HOME, cluster)
    @read = Standalone.new(HOME, cluster, source)
  end

  def read_internal(context)
    # run the job
    @bootstrap.exec(context)
    @read.exec(context)
  end
end
