
require 'schema/dynamo'

class Schema

  def initialize
    @home = ENV['SCHEMA_HOME']
    raise "SCHEMA_HOME not defined in environment variables - it must be!" unless !@home.nil?
    @dynamo = Dynamo.new
  end

  def start_store
    @dynamo.start
  end

  def create(org, metric, schema)
    # use the schema store java to create a schema at a location
    @home
  end

  def cleanup
    @dynamo.cleanup
  end

end
