
require 'ostruct'
require 'components/base_component'
require 'components/drill/drill_component'

class DrillLocal < BaseComponent
  include DrillComponent

  DRILL = "io.fineo.read.drill.e2e.ReadFromDrillLocal"

  def initialize(source)
    super('DRILL_LOCAL_READ_HOME')
    @source = source
  end

  def read_internal(context)
    java(aws_jars(), DRILL, context.opts, "local")
  end
end
