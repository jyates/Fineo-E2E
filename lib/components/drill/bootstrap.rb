
require 'components/base_component'

class Bootstrap < BaseComponent

  BOOTSTRAP = "io.fineo.read.drill.e2e.Bootstrap"

  def initialize(home, cluster)
    super(home)
    @cluster = cluster
  end

  def exec(context)
    java(JavaJars.find_jars(@home, "bootstrap"), BOOTSTRAP, context.opts, "")
  end

end
