
require 'components/drill/local'

class BaseDrill
 def initialize()
  end

  def start
  end

  def org!(org)
    @org = org
  end

  def drill_component?
    DrillLocal.new()
  end

  def stop
  end
end
