
require 'components/base_component'

class Bootstrap < BaseComponent

  def initialize(home, cluster)
    super(home)
    @cluster = cluster
  end

  def exec(context)
    setup_dir(context.dir)
    java(JavaJars.find_jars(@home, "bootstrap"), "io.fineo.read.drill.e2e.Bootstrap", context.opts, "")
  end

end
