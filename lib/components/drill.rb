
require 'components/base_component'

class Drill < BaseComponent

  DYNAMO = lambda { |context|
     context.opts["--dynamo-table-prefix"] = context.prefix
     File.join(context.dir, "read-dynamo.json")
  }
  PARQUET = lambda { |context|
    context.opts["--batch-dir"] = context.batch
    File.join(context.dir, "read-parquet.json")
  }
  BOTH = lambda { |context|
    DYNAMO.call(context)
    PARQUET.call(context)
    File.join(context.dir, "read-both.json")
  }

  DRILL = "io.fineo.read.drill.e2e.EndToEndWrapper"

  def initialize
    super('DRILL_READ_HOME')
  end

  class CallContext
    attr_reader :opts, :org, :metric, :batch, :prefix, :dir
    def initialize(opts, org, metric, batch, prefix, dir)
      @opts = opts
      @org = org
      @metric = metric
      @batch = batch
      @prefix = prefix
      @dir = dir
    end
  end

  def read(opts, mode, org, metric, batch_output_dir, dynamo_table_prefix)
    file_dir = setup_dir("drill_read")
    context = CallContext.new(opts, org, metric, batch_output_dir, dynamo_table_prefix, file_dir)
    file = mode.call(context)
    opts["--output"] = file
    opts["--org"] = org
    opts["--metric"] = metric

    ENV['DEBUG'] = "1"
    java(aws_jars(), DRILL, opts, "local")
    file
  end
end
