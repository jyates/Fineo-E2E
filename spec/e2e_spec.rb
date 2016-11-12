# Rspec based file for running end-to-end testing of the Fineo infrastructure

require 'e2e/runner'
require 'util/run'
require 'spec_helper'

RSpec.describe E2ERunner, "#e2e_testing" do
  context "with a local cluster" do
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
      validate(state, [event])
    end

    it "has the correct JDBC info for the user", :mode => 'jdbc' do
      @e2e.drill!("standalone")
      @e2e.schema!(ORG_ID, METRIC_NAME, schema?())
      event = @e2e.event!(event?())
      # skip batch processing - we just care that the Readerator is correctly interacting with Drill
      state = @e2e.create_schema().send_event().run()

      # just validate that we read the data correctly. Ensures that we bootstrapped the cluster properly
      expect([event]).to eq state.read_dynamo(ORG_ID, METRIC_NAME)

      puts 
      puts " ----- Validating JDBC Metadata ------"
      # Catalog
      expect([{
          "CATALOG_NAME" => "FINEO",
          "CATALOG_DESCRIPTION" => "Tables hosted by Fineo",
          "CATALOG_CONNECT" => ""
      }]).to eq state.drill_sql(ORG_ID, "SELECT * FROM INFORMATION_SCHEMA.CATALOGS")

      # Schemas
      expect([
          {"SCHEMA_NAME" => "INFORMATION_SCHEMA"},
          {"SCHEMA_NAME" => "FINEO"}
      ]).to eq state.drill_sql(ORG_ID, "SHOW SCHEMAS")

      # tables
      expect([
        info_table("CATALOGS"),
        info_table("COLUMNS"),
        info_table("SCHEMATA"),
        info_table("TABLES"),
        info_table("VIEWS"),
        table_row("FINEO", METRIC_NAME)
        ]).to eq state.drill_sql(ORG_ID, "SELECT * from INFORMATION_SCHEMA.`TABLES`")
    end
  end

  def info_table(name)
    return table_row("INFORMATION_SCHEMA", name)
  end

  def table_row(schema, name)
    return {
      "TABLE_CATALOG" => "FINEO",
      "TABLE_SCHEMA" => schema,
      "TABLE_NAME" => name,
      "TABLE_TYPE" => "TABLE"
    }
  end

  def validate(e2e, events)
    puts "Trying to read from dynamo...."
    expect(events).to eq e2e.read_dynamo(ORG_ID, METRIC_NAME)

    puts "Trying to read from parquet files...."
    expect(events).to eq e2e.read_parquet(ORG_ID, METRIC_NAME)

    puts "Trying to read from dynamo && parquet files...."
    # read from 'both', but really just dynamo b/c we filter out older parquet files
    expect(events).to eq e2e.read_all(ORG_ID, METRIC_NAME)
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
