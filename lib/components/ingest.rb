
require 'components/base_component'
require 'util/json_helper'
require 'util/run'

class Ingest < BaseComponent

  INGEST = "io.fineo.stream.processing.e2e.EndToEndWrapper"

  attr_reader :store_prefix

  def initialize
    super('INGEST_WRITE_HOME')
    @store_prefix = "ingest-e2e_test-#{Random.rand(100000)}"
  end

  def send(options, org_id, user_metric_name, events)
    file_dir = setup_dir("events")
    file = JsonHelper.write(file_dir, "event", events)
    options["--json"] = File.absolute_path(file)

    options["--ingest-table-prefix"] = @store_prefix

    output_dir = File.join(file_dir, "output")
    Dir.mkdir output_dir
    output = File.join(output_dir, "output.avro")
    options["--firehose-output"] = output

    java(aws_jars(), INGEST, options, "local")
    output_dir
  end
end
