
require 'ostruct'
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

  def initialize(home, addtl_opts={}, command)
    super(home)
    @addtl_opts = addtl_opts
    @command = command
  end

  def read(opts, mode, org, metric, batch_output_dir, dynamo_table_prefix)
    file_dir = setup_dir("drill_read")
    context = OpenStruct.new(:opts => opts, :org => org, :metric => metric,
      :batch => batch_output_dir, :prefix => dynamo_table_prefix, :dir => file_dir)
    file = mode.call(context)
    opts["--output"] = file
    opts["--org"] = org
    opts["--metric"] = metric

    java(aws_jars(), DRILL, opts.merge(@addtl_opts), @command)
    file
  end

end
