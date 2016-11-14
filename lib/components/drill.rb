
require 'ostruct'
require 'components/base_component'
require 'components/drill/local'
require 'components/drill/remote'

module Drill

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

  def self.from(cluster, source=nil)
    case source
    when nil,"local"
      DrillLocal.new(source)
    when "avatica", "fineo-local", "fineo-aws"
      DrillRemote.new(cluster, source)
    end
  end
end
