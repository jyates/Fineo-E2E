
require 'util/params'
require 'util/run'
require 'util/command'
require 'resources/base_resource'
# Manage a local spark cluster

class Spark < Resource
  include Params
  include Run

  def initialize
    super('spark.tar.gz', "spark")
    # default port for spark master
    @port = 7077
    @hostname = `hostname`.strip
  end

  # invokes the spark-submit script
  def submit(jars, clazz, args_hash)
    # basic command
    cmd = "#{@dir}/bin/spark-submit --class #{clazz}" \
      + " --master spark://#{@hostname}:#{@port}"
      # local mode will fail the test if the job fails and log output to console... easier for now
      #+ " --deploy-mode cluster"

    jar = jars.shift
    if jars.size > 0
      supporting = jars.join ","
      cmd.concat " --jars #{supporting}"
    end

    cmd.concat " #{jar}"

    cmd.concat " #{Command.spaces(args_hash)}"
    cmd.concat log?
    log_class_start(clazz)
    run cmd
  end

  def start
    return if @started
    unpack
    # start the cluster
    @dir = "#{@working}/spark-1.6.2-bin-hadoop2.6"
    # need MASTER_IP to ensure that slave and master can connect
    @sbin = "SPARK_MASTER_IP=#{@hostname} #{@dir}/sbin"
    run('echo "--- Starting Spark -----" >> tmp/out.log', false)
    run "#{@sbin}/start-master.sh #{log?()}"
    run "#{@sbin}/start-slave.sh spark://#{@hostname}:#{@port} #{log?()}"
    @started = true
  end

  def stop
    return unless @started
    run "#{@sbin}/stop-all.sh #{log?()}"
  end
end
