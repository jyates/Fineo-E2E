
require 'components/drill/local'

class BaseDrill
 def initialize()
  end

  def start
  end

  def drill_component?
    DrillLocal.new()
  end

  def stop
  end
end
