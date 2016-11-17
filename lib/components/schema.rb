
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
  def create(opts, org, metric, field_schemas)
    schema_dir = setup_dir("schema")

    request = create_request(org, metric)
    schema_run(opts, schema_dir, "createOrg", request)

    request = create_request(org, metric, true)
    schema_run(opts, schema_dir, "createMetric", request)

    field_schemas.each{|key, value|
      create_field_internal(opts, request.merge({}), key, value)
    }
  end

  def create_fields(opts, org, metric, field_hash)
    request = create_request(org, metric, true)
    field_hash.each{|key, value|
      create_field_internal(opts, request.merge({}), key, value)
    }
  end

private

  def create_request(org, metric, body=false)
    request = { "orgId" => org}
    request["body"] = {"metricName" => metric} if body
    return request
  end

  def create_field_internal(opts, request, name, type_info)
    schema_dir = setup_dir("schema")
    request["body"]["fieldName"] = name
    request["body"].merge!(type_info)
    schema_run(opts, schema_dir, "addField", request)
  end

  # Run the schema update
    def schema_run(opts, dir, cmd, request)
      dir = File.absolute_path(dir)
      # write the request to a json file
      out = JsonHelper.write(dir, cmd, request)
      opts["--json"] = out
      java(aws_jars(), E2E, opts, cmd)
    end
end
