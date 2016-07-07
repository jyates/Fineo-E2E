
require 'components/base_component'

class Drill < BaseComponent

  DRILL_LOCAL = "io.fineo.read.drill.e2e.DrillLocalClusterE2E"

  def initialize
    super('DRILL_READ_HOME')
  end

  def read(org, metric)
    @org = org
    @metric = metric
    self
  end

  def from(batch_output_dir)
    # wait for input
    `read`
  end
end
