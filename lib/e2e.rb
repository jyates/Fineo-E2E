# Main entry point for running the E2E testing

require 'util/params'

require 'resources/dynamo'
require 'resources/spark'

require 'components/schema'
require 'components/ingest'
require 'components/batch'
require 'components/drill'

class E2E

  def initialize
    @dynamo = Dynamo.new
    @spark = Spark.new

    @schema = Schema.new
    @ingest = Ingest.new
    @batch = Batch.new
    @drill = Drill.new

    ensure_working_dir
  end

  def ensure_working_dir
    FileUtils.rm_rf Params::WORKING_DIR if Dir.exists?(Params::WORKING_DIR)
    Dir.mkdir Params::WORKING_DIR
  end

  def start_store
    @dynamo.start
    @schema.start_store(@dynamo)
  end

  def create_schema(org, metric, schema)
    @schema.create(org, metric, schema)
    @base_opts = @schema.base_opts
  end

  def send_event(org, metric, event)
    @firehose = @ingest.send(@base_opts.clone, org, metric, event)
  end

  # Do the batch processing step from the output file via spark
  def batch_process
    @spark.start
    @output = @batch.process(@base_opts.clone, @firehose, @spark)
  end

  def read(org, metric)
    @drill.read(org, metric).from(@output)
  end

  def cleanup
    @spark.stop
    @dynamo.cleanup
  end
end
