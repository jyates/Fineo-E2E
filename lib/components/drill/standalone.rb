
require 'components/base_component'

class Standalone < BaseComponent

  DRILL = "io.fineo.read.drill.e2e.EndToEndWrapper"

  def initialize(home, cluster, source)
    super(home)
    @cluster = cluster
    @source = source
  end

  def exec(context)
    opts = context.opts
    # aws credentials
    opts["--auth-profile-name"] = "test-user" if @source == "fineo-aws"

    # standard options
    opts["--jdbc-host"] = @cluster.host?
    opts["--jdbc-port"] = @cluster.port?

    # remove the options we don't need

    # hit it!
    #Run.enableDebugging 5006
    java(aws_jars(), DRILL, context.opts, @source)
  end
end
