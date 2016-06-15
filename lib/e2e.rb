# Main entry point for running the E2E testing

require 'drill'
require 'ingest'
require 'schema'
require 'util/params'

class E2E

  def initialize
    @schema = Schema.new
    @ingest = Ingest.new
    @drill = Drill.new

    ensure_working_dir
  end

  def ensure_working_dir
    FileUtils.rm_rf Params::WORKING_DIR if Dir.exists?(Params::WORKING_DIR)
    Dir.mkdir Params::WORKING_DIR
  end

  def start_store
    @schema.start_store
  end

  def create_schema(org, metric, schema)
    @schema.create(org, metric, schema)
  end

  def send_event(org, metric, event)
    @output_dir = @ingest.send(org, metric, event)
  end

  def read(org, metric)
    @drill.read(org, metric).from(@output_dir)
  end

  def cleanup
    @schema.cleanup
  end
end
