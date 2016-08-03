
require 'components/drill'

class DrillRemote < Drill

  def initialize(addtl_opts={})
    super('DRILL_REMOTE_READ_HOME', addtl_opts, "remote")
  end
end
