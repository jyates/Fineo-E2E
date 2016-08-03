# Main entry point for running the E2E testing

require 'util/params'

require 'components/schema'
require 'components/ingest'
require 'components/batch'
require 'components/drill'

require 'json'
require 'util/run'

class E2EState

  def initialize(dynamo, spark, drill_cluster)
    @dynamo = dynamo
    @spark = spark
    @drill_cluster = drill_cluster

    @schema = Schema.new
    @ingest = Ingest.new
    @batch = Batch.new
    @drill = Drill.new
  end

  def base_opts
    {
      "--host" => "localhost",
      "--port" => @dynamo.port,
      "--schema-table" => @schema.store_table
    }
  end

  def create_schema(org, metric, schema)
    @schema.create(base_opts(), org, metric, schema)
  end

  def send_event(org, metric, event)
    @firehose = @ingest.send(base_opts(), org, metric, event)
  end

  # Do the batch processing step from the output file via spark
  def batch_process
    @output = @batch.process(base_opts(), @firehose, @spark)
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

private

  def read_drill(mode, org, metric)
    read = @drill.read(base_opts(), mode, org, metric, @output, @ingest.store_prefix)
    # read the data
    file = File.read(read)
    JSON.parse(file)
  end

end
