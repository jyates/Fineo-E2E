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

    it "ingests a data without a schema, but then can read it when we apply schema", :mode => 'evolve_schema_varchar' do
      @e2e.drill!("standalone")
      @e2e.schema!(ORG_ID, METRIC_NAME, schema?())

      raw_event = event?()
      raw_event["field2"] = "world"
      event = @e2e.event!(raw_event)
      # just do dynamo for right now.
      state = @e2e.create_schema().send_event().run()

      # initial read will not have field2 - its not in the schema
      event.delete("field2")
      expect([event]).to eq state.read_dynamo(ORG_ID, METRIC_NAME)

      # add field2 to the schema
      state.create_fields(ORG_ID, METRIC_NAME, {
        "field2" => {
          "aliases" => [],
          "fieldType" => "VARCHAR"
        }
      })

      # now we should be able to read the field
      event["field2"] = "world"
      expect([event]).to eq state.read_dynamo(ORG_ID, METRIC_NAME)
    end

    it "ingests a data without a schema, but then can read it when we apply schema", :mode => 'evolve_schema_number' do
      @e2e.drill!("standalone")
      @e2e.schema!(ORG_ID, METRIC_NAME, schema?())

      raw_event = event?()
      raw_event["field2"] = "1"
      event = @e2e.event!(raw_event)
      # just do dynamo for right now.
      state = @e2e.create_schema().send_event().run()

      # initial read will not have field2 - its not in the schema
      event.delete("field2")
      expect([event]).to eq state.read_dynamo(ORG_ID, METRIC_NAME)

      # add field2 to the schema
      state.create_fields(ORG_ID, METRIC_NAME, {
        "field2" => {
          "aliases" => [],
          "fieldType" => "INTEGER"
        }
      })

      # now we should be able to read the field
      event["field2"] = 1
      expect([event]).to eq state.read_dynamo(ORG_ID, METRIC_NAME)
      puts " --- read field successfully --"
    end

    it "evolves schema for an alias field", :mode => 'alias' do
      @e2e.drill!("standalone")
      schema = schema?()
      schema["field2"] = {
          "aliases" => ["f2"],
          "fieldType" => "INTEGER"
      }
      @e2e.schema!(ORG_ID, METRIC_NAME, schema)

      raw_event = event?()

      raw_event2 = raw_event.clone
      raw_event2["field2"] = 1
      raw_event2["timestamp"] = raw_event["timestamp"] +1

      raw_event3 = raw_event2.clone
      raw_event3.delete("field2")
      raw_event3["f2"] = 2
      raw_event3["timestamp"] = raw_event2["timestamp"] +1

      events = @e2e.events!([raw_event, raw_event2, raw_event3])
      # #startup - skip validation b/c there is something wrong with how we read data from dynamo. still comes out fine in drill reads, so w/e
      state = @e2e.create_schema().send_event().skip_ingest_validation().run()

      # validate reading (with corrections for schema resolution on read)
      events[0]["field2"] = nil
      events[2]["field2"] = events[2].delete("f2")
      expect(state.read_dynamo(ORG_ID, METRIC_NAME)).to eq events
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

      # columns
      expect([{
        "TABLE_CATALOG" => "FINEO",
        "TABLE_SCHEMA" => "FINEO",
        "TABLE_NAME" => METRIC_NAME,
        "COLUMN_NAME" => "timestamp",
        "ORDINAL_POSITION" => 1,
        "DATA_TYPE" => "BIGINT"
      },{
        "TABLE_CATALOG" => "FINEO",
        "TABLE_SCHEMA" => "FINEO",
        "TABLE_NAME" => METRIC_NAME,
        "COLUMN_NAME" => "field1",
        "ORDINAL_POSITION" => 2,
        "DATA_TYPE" => "BOOLEAN"
      }]).to eq state.drill_sql(ORG_ID, "SELECT " +
        "TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, ORDINAL_POSITION, DATA_TYPE" +
        " FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME like '#{METRIC_NAME}'")
    end

    it "allows select * from (values(1))", :mode => 'select_values' do
      @e2e.drill!("standalone")
      @e2e.schema!(ORG_ID, METRIC_NAME, schema?())
      event = @e2e.event!(event?())
      @e2e.skip_batch_process_for_testing!
      state = @e2e.run
      expect([{
        "EXPR$0" => 1
       }]).to eq state.drill_sql(ORG_ID, "select * from (values(1))")
    end

    it "has a working proxy server", :mode => 'proxy' do
      @e2e.drill!("standalone")
      @e2e.schema!(ORG_ID, METRIC_NAME, schema?())
      event = @e2e.event!(event?())
      @e2e.skip_batch_process_for_testing!
      state = @e2e.run

      # generic select values
      expect([{
        "EXPR$0" => 1
       }]).to eq state.proxy_drill_sql(ORG_ID, "select * from (values(1))")

      # reading an actual event
      expect([event]).to eq state.proxy_drill_sql(ORG_ID, "select * from #{METRIC_NAME}")

      # ensure that bad queries generate a 'good' response format
      response = state.proxy_drill_sql(ORG_ID, "select bad_request", false)
      expect(response).to be_instance_of(Net::HTTPBadRequest)
      body = JSON.parse(response.body)
      expect(body['code']).to eq 400
      expect(body['message']).to start_with "Error -1 (00000) : Error while executing SQL"
    end
  end

  def send_event(e2e, state, event)
    e2e.clear_steps()
    expected_event = e2e.event!(event)
    e2e.send_event().run(state)
    return expected_event
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
