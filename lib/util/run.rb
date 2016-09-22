
require "util/params"
require "util/command"

module Run

  next_port = 5005
  LOG = ">> tmp/out.log 2>> tmp/error.log"

  def self.enableDebugging(port=5005)
    ENV['DEBUG'] = "1"
    ENV['DISABLE_DEBUG_AFTER'] = "1"
    ENV['DEBUG_PORT']=port.to_s
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

    if Params.env('DEBUG', '').empty?
      suspend =  'n'
      suspend_text = ""
    else
      suspend == 'y'
      suspend_text = " ==SUSPENDED=="
    end

    port = Params.env('DEBUG_PORT', next_port)
    next_port = next_port + 1
    puts " -------#{suspend_text} Please connect to remote JVM at: #{port} -------- "
    command << "-Xdebug -Xrunjdwp:server=y,transport=dt_socket,suspend=#{suspend},address=#{port} "
    ENV['DEBUG'] = nil if !(ENV['DISABLE_DEBUG_AFTER'].nil?)

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
