# Rspec based file for running end-to-end testing of the Fineo infrastructure

require 'e2e'
require 'spec_helper'
require 'util/run'

RSpec.describe E2E, "#start" do
  context "with a local e2e setup" do
    before(:each) do
      @e2e = E2E.new
    end

    after(:each) do
      puts "=== Cleanup ==="
      @e2e.cleanup
    end

    # TODO Switch to using a context and nested 'it' states
    it "ingests, batch processes and reads a row" do
      @e2e.start_store

      # setup the event we want to send
      org_id = "org1"
      metric_id = "metric1"

      schema = {
        "field1" =>{
          "aliases" => [],
          "fieldType" => "BOOLEAN"
        }
      }
      @e2e.create_schema(org_id, metric_id, schema)

      event = {
        "companykey" => org_id,
        "metrictype" => metric_id,
        # 1980, so we fit within Drill's epoch
        "timestamp" => 315532800000,
        "field1" => true
      }
      @e2e.send_event(org_id, metric_id, event)

      # cleanup the event for what we actually exepct to read back
      event.delete("companykey")
      event.delete("metrictype")

      # read from dynamo
      validate(event, @e2e.read_dynamo(org_id, metric_id), "dynamo")

      # convert to parquet and correct directory structure
      @e2e.batch_process

      # read from parquet
      validate(event, @e2e.read_parquet(org_id, metric_id), "the underlying files")

      # read from 'both', but really just dynamo b/c we filter out older parquet files
      validate(event, @e2e.read_all(org_id, metric_id), '"both" dynamo and parquet')
    end

    def validate(event, events, source)
      expect([event]).to eq events
    end
  end
end
