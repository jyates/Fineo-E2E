# Main entry point for running the E2E testing

require 'util/params'

require 'resources/dynamo'
require 'resources/spark'

require 'components/schema'
require 'components/ingest'
require 'components/batch'
require 'components/drill'

require 'json'
require 'util/run'

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

  def read_dynamo(org, metric)
    read_drill(Drill::DYNAMO, org, metric)
  end

  def read_parquet(org, metric)
    read_drill(Drill::PARQUET, org, metric)
  end

  def read_all(org, metric)
    read_drill(Drill::BOTH, org, metric)
  end

  def cleanup
    @spark.stop
    @dynamo.cleanup
  end

  def start_spark
    @spark.start
  end

private

  def read_drill(mode, org, metric)
    read = @drill.read(@base_opts.clone, mode, org, metric, @output, @ingest.store_prefix)
    # read the data
    file = File.read(read)
    JSON.parse(file)
  end

end
