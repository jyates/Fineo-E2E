# Rspec based file for running end-to-end testing of the Fineo infrastructure

require 'e2e'

RSpec.describe E2E, "#start" do
  context "with a local e2e setup" do
    before(:each) do
      @e2e = E2E.new
    end

    after(:each) do
      puts "=== Cleanup ==="
      @e2e.cleanup
    end

    it "ingests and writes on row" do
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
        "timestamp" => 1234,
        "field1" => true
      }
      @e2e.send_event(org_id, metric_id, event)

      # convert to parquet and correct directory structure
      @e2e.batch_process

      events = @e2e.read(org_id, metric_id, event)
      assert_equals([event], events, "Didn't read the right event from the underlying files!")
    end
  end
end
