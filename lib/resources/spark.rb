
require 'util/params'
require 'util/run'
require 'util/command'

# Manage a local spark cluster
class Spark
  SPARK_IN = 'ext/spark.tar.gz'

  include Params
  include Run

  def initialize
    # default port for spark master
    @port = 7077
  end

  # invokes the spark-submit script
  def submit(jars, clazz, args_hash)
    # basic command
    cmd = "#{@dir}/bin/spark-submit --class #{clazz}" \
      + " --master spark://localhost:#{@port}"
      # local mode will fail the test if the job fails and log output to console... easier for now
      #+ " --deploy-mode cluster"

    jar = jars.shift
    if jars.size > 0
      supporting = jars.join ","
      cmd.concat " --jars #{supporting}"
    end

    cmd.concat " #{jar}"

    cmd.concat " #{Command.spaces(args_hash)}"
    run("echo ---- SPARK: #{clazz} ----- >> tmp/out.log", false)
    run cmd
  end

  def start
    # Create working directory
    dir = File.join(Params::WORKING_DIR, "spark")
    Dir.mkdir(dir)
    ret = system("tar -xf #{SPARK_IN} -C #{dir}")
    raise("Could not unpack dynamo #{SPARK_IN} => #{dir}") unless ret

    # start the cluster
    @dir = "#{dir}/spark-1.6.2-bin-hadoop2.6"
    @sbin = "#{@dir}/sbin"
    run "#{@sbin}/start-all.sh"
    @started = true
  end

  def stop
    return unless @started
    run "#{@sbin}/stop-all.sh"
  end
end
