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

    ORG_ID = "pmV5"
    METRIC_NAME = "metric1"

    it "runs a standalone instance with a row of data", :mode => 'local_standalone' do
      @e2e.drill!("standalone")
      @e2e.schema!(ORG_ID, METRIC_NAME, schema?())
      raw_event = event?()
      raw_event["field2"] = "hello"
      event = @e2e.event!(raw_event)
      
      # run a sub-set of steps, so we don't run a spark cluster...hopefully
      state = @e2e.create_schema().send_event().run()
      
      puts
      # e.g. setup drill and validate that the data is present
      puts "----- Setting up Read Server ----"
      puts
      # initial read will not have field2 - its not in the schema
      event.delete("field2")
      expect([event]).to eq state.read_dynamo(ORG_ID, METRIC_NAME)
      # print the current locations of everything so we can connect
      puts
      puts "--------------------------------------------------------"
      puts "ORG_ID: #{ORG_ID}"
      puts "With metrics: #{METRIC_NAME}"
      puts "Local resources:"
      drill = state.drill_cluster
      puts "SQL:"
      puts "\Proxy server URL: \n\t\thttp://#{drill.proxy_host?}:#{drill.proxy_port?}"
      puts "\tReaderator server URL: \n\t\tjdbc:fineo:url=http://#{drill.host?}:#{drill.port?};api_key=#{ORG_ID}"
      puts "\tDrill zookeeper URL: \n\t\tjdbc:drill:zk=#{drill.host?}:2181"
      puts "Other:"
      puts "\tDynamo web console: http://#{drill.host?}:8000/shell"
      puts "--------------------------------------------------------"

      puts
      puts "Hit any key to continue...."
      STDIN.gets

      puts
      puts "Updating the schema to include 'field2' as a VARCHAR"
      # add field2 to the schema
      state.create_fields(ORG_ID, METRIC_NAME, {
        "field2" => {
          "aliases" => [],
          "fieldType" => "VARCHAR"
        }
      })
      event["field2"] = "hello"
      expect([event]).to eq state.read_dynamo(ORG_ID, METRIC_NAME)

      puts
      puts "Hit any key to terminate the cluster...."
      STDIN.gets
    end
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
