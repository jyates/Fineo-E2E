
require 'schema/dynamo'

class Schema

  def initialize
    @home = ENV['SCHEMA_HOME']
    @dynamo = Dynamo.new
  end

  def start_store
    @dynamo.start
  end

  def cleanup
    @dynamo.cleanup
  end

end
