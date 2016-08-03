
require 'ostruct'
require 'components/drill'

class DrillLocal < Drill

  def initialize()
    super('DRILL_LOCAL_READ_HOME', {}, "local")
  end
end
