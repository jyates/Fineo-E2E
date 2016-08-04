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
    
    ORG_ID = "org1"
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
      state = @e2e.run
      validate(state, [event])
    end
  end

  def validate(e2e, events)
    # read from dynamo
    #Run.enableDebugging
    expect(events).to eq e2e.read_dynamo(ORG_ID, METRIC_NAME)

    # read from parquet
    expect(events).to eq e2e.read_parquet(ORG_ID, METRIC_NAME)

    # read from 'both', but really just dynamo b/c we filter out older parquet files
    expect(events).to eq e2e.read_all(ORG_ID, METRIC_NAME)
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
