
require 'util/run'
require 'components/base_component'

# Run a spark batch processing job
class Batch < BaseComponent

  include Run
  JOB = "io.fineo.etl.spark.SparkETL"
  BATCH = "io.fineo.batch.processing.e2e.SparkE2ETestRunner"

  def initialize
    super('BATCH_ETL_HOME')
  end

  def process(args, input, spark)
    dir = setup_dir("batch")

    input = File.absolute_path(input)
    output = File.absolute_path(File.join(dir, "output"))
    archive = File.absolute_path(File.join(dir, "archive"))
    args["--source"] = input
    args["--completed"] = output
    args["--archive"] = archive

    spark.submit(aws_jars(), BATCH, args)
    output
  end
end
