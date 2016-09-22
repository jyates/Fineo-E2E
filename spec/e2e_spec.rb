# Rspec based file for running end-to-end testing of the Fineo infrastructure

require 'e2e/runner'
require 'util/run'
require 'spec_helper'

RSpec.describe E2ERunner, "#start" do
  context "with a local e2e setup" do
    before(:each) do
      @e2e = E2ERunner.new
    end

    after(:each) do
      puts "=== Cleanup ==="
      @e2e.cleanup
    end

    # jesse-test-key API KEY from AWS API Gateway
    ORG_ID = "pmV5QkC0RG7tHMYVdyvgG8qLgNV79Swh3XIiNsF1"
    METRIC_NAME = "metric1"

    it "ingests, batch processes and reads a row", :mode => 'local' do
      @e2e.drill!("local")
      @e2e.schema!(ORG_ID, METRIC_NAME, schema?())
      event = @e2e.event!(event?())
      state = @e2e.run
      validate(state, [event])
    end

    it "does e2e processing with a standalone drill cluster", :mode => 'standalone' do
      @e2e.drill!("standalone")
      @e2e.schema!(ORG_ID, METRIC_NAME, schema?())
      event = @e2e.event!(event?())
      #@e2e.skip_batch_process_for_testing!
      state = @e2e.run
      validate(state, [event], "fineo-local")
    end
  end

  def validate(e2e, events, source=nil)
    puts "Trying to read from dynamo...."
    expect(events).to eq e2e.read_dynamo(ORG_ID, METRIC_NAME, source)

    puts "Trying to read from parquet files...."
    expect(events).to eq e2e.read_parquet(ORG_ID, METRIC_NAME, source)

    puts "Trying to read from dynamo && parquet files...."
    # read from 'both', but really just dynamo b/c we filter out older parquet files
    expect(events).to eq e2e.read_all(ORG_ID, METRIC_NAME, source)
  end

  def schema?
    {
      "field1" =>{
        "aliases" => [],
        "fieldType" => "BOOLEAN"
      }
    }
  end

  def event?
    {
      "companykey" => ORG_ID,
      "metrictype" => METRIC_NAME,
      # 1980, so we fit within Drill's epoch
      "timestamp" => 315532800000,
      "field1" => true
    }
  end
end
