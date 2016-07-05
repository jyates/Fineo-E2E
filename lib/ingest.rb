
require 'util/params'
require 'util/json_helper'

class Ingest
  def initialize
    @home = ENV['INGEST_WRITE_HOME']
  end

  def send(org_id, user_metric_name, event_hash)
    file_dir = File.join(Params::WORKING_DIR, "events")
    file = JsonHelper.write(file_dir, "event", event_hash)
  end
end
