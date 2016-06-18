
require 'schema/dynamo'
require 'util/params'
require 'json'

class Schema

   E2E = "io.fineo.lambda.handle.schema.e2e.EndtoEndWrapper"

  def initialize
    @home = ENV['SCHEMA_HOME']
    raise "SCHEMA_HOME not defined in environment variables - it must be!" unless !@home.nil?
    @dynamo = Dynamo.new
  end

  def start_store
    @dynamo.start
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
      ending = 0
      out = File.join(dir, "#{cmd}.json")
      # find a new ending for the command request file
      while(File.exists?(out)) do
          ending = ending +1
          out = out+ending
      end

      Dir.mkdir dir unless Dir.exists? dir
      File.open(out,"w") do |f|
        f.write(request.to_json)
      end

      # run the request against the deployable e2e jars
      absolute = File.absolute_path(@home)
      jars = Dir.entries(@home).delete_if{|file| !file.end_with?("aws.jar")}
      jars.map! {|jar| File.join(absolute, jar)}

      debug = "-Xdebug -Xrunjdwp:server=y,transport=dt_socket,address=5005,suspend=y"
      #debug = ""
      cmd = "java #{debug} -cp #{jars.join(':')} #{E2E} --json #{out} --host localhost --port #{@dynamo.port} #{cmd}"
      puts "Running: #{cmd}"
      `#{cmd}`
      raise "Could not run '#{cmd}' with request: #{request}!" unless $? == 0
    end


end
