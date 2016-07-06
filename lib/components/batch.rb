
require 'util/params'
require 'util/javajars'

# Run a spark batch processing job
class Batch

  JOB = "io.fineo.etl.spark.SparkETL"
  BATCH = "io.fineo.batch.processing.e2e.EndToEndWrapper"

  def initialize
    @home = Params.env_require 'BATCH_ETL_HOME'
  end

  def process(opts, input, spark)
    dir = File.join(Params::WORKING_DIR, "batch")
    Dir.mkdir dir unless Dir.exists? dir

    input = File.absolute_path(input)
    output = File.absolute_path(File.join(dir, "output"))
    archive = File.absolute_path(File.join(dir, "archive"))

    if spark.nil?
      local input, output, archive, opts
    else
      remote input, output, archive, opts
    end
  end

  def local
    absolute = File.absolute_path(@home)
    jars = JavaJars.find_aws_jars(absolute)

     # setup command options
     cmd_opts = {"--input" => input, "--output" => output, "--archive" => archive}
  end

  def remote(input, output, archive, opts)
    # convert the standard options into the one that job understands

     --host localhost --port 8000 --schema-table schema-table_test-27473 local --input /Users/jyates/dev/iot-startup/platform-end2end/tmp/events/output.avro --output /Users/jyates/dev/iot-startup/platform-end2end/tmp/batch/output --archive /Users/jyates/dev/iot-startup/platform-end2end/tmp/batch/archive
    args = {
      opts["host"] => ,
      "r" => input,
      "o" => output,
      "e" => File.absolute_path(File.join(dir, "error")),
      "a" => archive,
    }

    # find the jar
    absolute = File.absolute_path(@home)
    jars = JavaJars.find_aws_jars(absolute)

    spark.submit(jars, BATCH, opts, "local", cmd_opts)
    output
  end
end
