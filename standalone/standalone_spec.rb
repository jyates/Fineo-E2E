# Rspec based file for running end-to-end testing of the Fineo infrastructure

require 'e2e/runner'
require 'util/run'
require 'spec_helper'

RSpec.describe E2ERunner, "#start" do
  context "end-to-end for local testing" do
    before(:each) do
      @e2e = E2ERunner.new
    end

    after(:each) do
      puts "=== Cleanup ==="
      @e2e.cleanup
    end

     # jesse-test-key API KEY from AWS API Gateway
    ORG_ID = "pmV5QkC0RG7tHMYVdyvgG8qLgNV79Swh3XIiNsF1"
    METRIC_NAME = "metric"

    it "runs a standalone instance with a row of data", :mode => 'local_standalone' do
      @e2e.drill!("standalone")
      @e2e.schema!(ORG_ID, METRIC_NAME, schema?())
      event = @e2e.event!(event?())
      
      # run a sub-set of steps, so we don't run a spark cluster...hopefully
      state = @e2e.create_schema().send_event().run()
      
      # print the current locations of everything so we can connect
      puts
      puts "--------------------------------------------------------"
      puts "ORG_ID: #{ORG_ID}"
      puts "With metrics: #{METRIC_NAME}"
      puts "Local resources:"
      drill = state.drill_cluster
      puts "\tReaderator server URL: \n\t\tjdbc:fineo:url=http://#{drill.host?}:#{drill.port?};api_key=#{ORG_ID}"
      puts "\tDrill zookeeper URL: \n\t\tjdbc:drill:zk=#{drill.host?}:2181"
      puts "--------------------------------------------------------"

      puts
      puts "Hit any key to terminate the cluster...."
      STDIN.gets
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

  def schema?(field_aliases=[])
    {
      "field1" => {
        "aliases" => field_aliases,
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