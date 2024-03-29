# Main entry point for running the E2E testing

require 'util/params'

require 'components/schema'
require 'components/ingest'
require 'components/batch'
require 'components/drill'

require 'json'
require 'util/run'

class E2EState

  attr_reader :dynamo, :drill_cluster

  def initialize(dynamo, drill_cluster, drill_mode, skip_ingest_validation = false)
    @dynamo = dynamo
    @drill_cluster = drill_cluster
    @drill_mode = drill_mode

    @schema = Schema.new
    @ingest = Ingest.new
    @ingest.skip_validation if skip_ingest_validation
    @batch = Batch.new
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

  def create_fields(org, metric, fields)
    @schema.create_fields(base_opts(), org, metric, fields)
  end

  def send_event(org, metric, event)
    @firehose = @ingest.send(base_opts(), org, metric, event)
  end

  # Do the batch processing step from the output file via spark
  def batch_process(spark)
    @output = @batch.process(base_opts(), @firehose, spark)
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

  def drill_sql(org, sql)
    read = Drill.from(@drill_cluster, @drill_mode)
      .with(Drill::DYNAMO, base_opts(), @output, @ingest.store_prefix)
      .read_sql(org, sql)
    # read the data
    file = File.read(read)
    JSON.parse(file)
  end

  def proxy_drill_sql(org, sql, fail_on_error_response=true)
    Drill.from(@drill_cluster, @drill_mode)
      .with(Drill::DYNAMO, base_opts(), @output, @ingest.store_prefix)
      .read_proxy_sql(org, sql, fail_on_error_response)
  end

private

  def read_drill(mode, org, metric)
    read = Drill.from(@drill_cluster, @drill_mode)
      .with(mode, base_opts(), @output, @ingest.store_prefix)
      .read(org, metric)
    # read the data
    file = File.read(read)
    JSON.parse(file)
  end

end
