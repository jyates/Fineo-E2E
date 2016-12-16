
require 'util/params'
require 'resources/base_resource'

class Dynamo < Resource
  DYNAMO_READY = 'Initializing DynamoDB Local with the following configuration:'

  include Params

  attr_accessor :port

  def initialize()
    super('dynamodb.tar.gz', "dynamo")
  end

  def start
    return if @started
    unpack

    @port = Params.env('DYNAMO_PORT', '8000')
    cmd = "java -Djava.library.path=#{@working}/DynamoDBLocal_lib -jar #{@working}/DynamoDBLocal.jar -inMemory -port #{@port}"
    spawn_process(cmd, self.method(:wait_for_dynamo))
  end

#-----------------------------------------
private
#-----------------------------------------

    def wait_for_dynamo(file, err)
      f = File.open(file,"r")
      f.seek(0,IO::SEEK_END)
      while true do
        select([f])
        line = f.gets
        return true if !line.nil? && line.start_with?(DYNAMO_READY)
        return false if ((File.exists? err) && (File.size(err)) > 0)
      end
    end
end
