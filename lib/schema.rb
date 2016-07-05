
require 'schema/dynamo'
require 'util/params'
require 'util/run'
require 'util/json_helper'
require 'util/javajars'

class Schema

  E2E = "io.fineo.lambda.handle.schema.e2e.EndtoEndWrapper"

  include Run

  def initialize
    @home = ENV['SCHEMA_HOME']
    raise "SCHEMA_HOME not defined in environment variables - it must be!" unless !@home.nil?
    @dynamo = Dynamo.new
  end

  def start_store
    @dynamo.start
    @store_table = "schema-table_test-#{Random.rand(100000)}"
  end

  # use the schema store java to create a schema at a location
  def create(org, metric, fields)
    schema_dir = File.join(Params::WORKING_DIR, "schema")

    request = { "orgId" => org}
    schema_run schema_dir, "createOrg", request

    request["metricUserName"] =  metric
    schema_run schema_dir, "createMetric", request

    fields.each{|key, value|
      # copy the hash values
      toSend = request.merge({})

      toSend["userFieldName"] = key
      # add the remaining fields directly
      toSend.merge!(value)

      schema_run(schema_dir, "addField", toSend)
    }
  end

  def cleanup
    @dynamo.cleanup
  end

private
  # Run the schema update
    def schema_run(dir, cmd, request)
      dir = File.absolute_path(dir)
      # write the request to a json file
      out = JsonHelper.write(dir, cmd, request)

      # run the request against the deployable e2e jars
      absolute = File.absolute_path(@home)
      jars = JavaJars.find_aws_jars(absolute)

      java(jars, E2E,
        {"--json" => out,
        "--host" => "localhost",
        "--port" => @dynamo.port,
        "--schema-table" => @store_table},
         cmd)
    end
end
