
require 'util/params'
require 'util/json_helper'
require 'util/javajars'
require 'util/run'

class Ingest

  INGEST = "io.fineo.stream.processing.e2e.EndToEndWrapper"
  include Run

  def initialize
    @home = Params.env_require 'INGEST_WRITE_HOME'
    @store_prefix = "ingest-e2e_test-#{Random.rand(100000)}"
  end

  def send(options, org_id, user_metric_name, event_hash)
    file_dir = File.join(Params::WORKING_DIR, "events")
    file = JsonHelper.write(file_dir, "event", event_hash)

    output = File.join(file_dir, "output.avro")
    absolute = File.absolute_path(@home)
    jars = JavaJars.find_aws_jars(absolute)

    options["--json"] = File.absolute_path(file)
    options["--ingest-table-prefix"] = @store_prefix
    options["--firehose-output"] = output

    #ENV['DEBUG']="jesse"
    java(jars, INGEST, options, "local")
    output
  end
end
