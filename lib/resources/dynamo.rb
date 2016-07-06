
require 'util/params'

class Dynamo

  DYNAMO_IN = 'ext/dynamodb.tar.gz'
  DYNAMO_READY = 'Initializing DynamoDB Local with the following configuration:'

  include Params

  attr_accessor :port

  def start
    dynamo = File.join(Params::WORKING_DIR, "dynamo")
    Dir.mkdir(dynamo)
    ret = system("tar -xf #{DYNAMO_IN} -C #{dynamo}")
    raise("Could not unpack dynamo #{DYNAMO_IN} => #{dynamo}") unless ret

    @port = Params.env('DYNAMO_PORT', '8000')
    cmd = "java -Djava.library.path=#{dynamo}/DynamoDBLocal_lib -jar #{dynamo}/DynamoDBLocal.jar -inMemory -port #{@port}"
    out = "#{dynamo}/out"
    err = "#{dynamo}/err"
    @pid = spawn("#{cmd}", :out => "#{out}", :err => "#{err}")
    Process.detach(@pid)
    raise "Dynamo didn't start correctly! See #{err} for more info" unless wait_for_dynamo(out, err)
    @started = true

    puts "(#{@pid}) Running dynamo from #{dynamo}. Output/errors are logged to that directory"
  end

  def cleanup
    return unless @started
    puts "Stopping local Dynamo(#{@pid})"
    system("kill -9 #{@pid}")
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
