
require 'components/base_component'
require 'util/params'
require 'util/run'
require 'util/json_helper'
require 'util/javajars'

class Schema < BaseComponent

  E2E = "io.fineo.lambda.handle.schema.e2e.EndtoEndWrapper"

  attr_reader :store_table

  def initialize
    super('SCHEMA_HOME')
    @store_table = "schema-table_test-#{Random.rand(100000)}"
  end

  # use the schema store java to create a schema at a location
  def create(opts, org, metric, fields)
    schema_dir = setup_dir("schema")

    request = { "orgId" => org}
    schema_run opts, schema_dir, "createOrg", request

    request["metricName"] =  metric
    schema_run opts, schema_dir, "createMetric", request

    fields.each{|key, value|
      # copy the hash values
      toSend = request.merge({})

      toSend["fieldName"] = key
      # add the remaining fields directly
      toSend.merge!(value)

      schema_run(opts, schema_dir, "addField", toSend)
    }
  end

private
  # Run the schema update
    def schema_run(opts, dir, cmd, request)
      dir = File.absolute_path(dir)
      # write the request to a json file
      out = JsonHelper.write(dir, cmd, request)
      opts["--json"] = out
      java(aws_jars(), E2E, opts, cmd)
    end
end
