
require "util/params"
require "util/command"

module Run

  LOG = ">> tmp/out.log 2>> tmp/error.log"

  def self.enableDebugging(port=5005, suspend="y")
    ENV['DEBUG'] = "1"
    ENV['DISABLE_DEBUG_AFTER'] = "1"
    ENV['DEBUG_PORT']=port.to_s
    ENV["DEBUG_SUSPEND"]=suspend
  end

  def run(command, log=true)
     puts "Running: #{command}" if log
     `#{command}`
     raise "FAILED: '#{command}'" unless $? == 0
     $?
  end

  def java(jars_list, clazz, args_hash, cmd, cmd_opts={})
    command = build_java_command(jars_list, clazz, args_hash, cmd, cmd_opts)
    command << " #{LOG}"

    log_class_start(clazz)
    result = run command
    return result
  end

  def build_java_command(jars_list, clazz, args_hash, cmd, cmd_opts={})
    command = "java "

    unless Params.env('DEBUG', '').empty?
      port = Params.env('DEBUG_PORT', 5005)
      suspend = ENV["DEBUG_SUSPEND"]
      puts " ------- Please connect to remote JVM at: #{port} (suspend: #{suspend})-------- "
      command << "-Xdebug -Xrunjdwp:server=y,transport=dt_socket,suspend=#{suspend},address=#{port} "
      ENV['DEBUG'] = nil if !(ENV['DISABLE_DEBUG_AFTER'].nil?)
    end

    jars = jars_list.join(':')
    raise "No jars found for class: #{clazz}!" if jars.empty?
    command << "-cp #{jars} "

    command << "#{clazz} "

    args = Command.spaces(args_hash)
    command << "#{args} "

    cmd.concat " #{Command.spaces(cmd_opts)}" unless cmd_opts.empty?
    command << "#{cmd}"
  end

  def log_class_start(clazz)
    run("echo ---- #{clazz} ----- >> tmp/out.log ", false)
    run("echo ---- #{clazz} ----- >> tmp/error.log ", false)
  end
end
