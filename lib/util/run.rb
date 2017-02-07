
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

  def run(command, log=false)
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

  # Build a java command to run
  # java -cp {clazz} {args_hash} {cmd} {cmd_opts}
  # Params:
  # +jars_list+:: list of jars to use in the classpath
  # +clazz+:: class name when building the command
  # +args_hash+:: hash of key:value arguments to use before the command
  # +cmd+:: logical command to run
  # +cmd_opts+:: hash of key:value arguments to use after the command
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

  # Build a java command to run
  # java {dashDprops} -jar {jar} {clazz} {args_hash} {cmd} {cmd_opts}
  # Params:
  # +dashDprops+:: hash of properties that will be joined like -D{hash}={value}
  # +jar+:: jar to use when running the command
  # +clazz+:: class name when building the command
  # +args_hash+:: hash of key:value arguments to use before the command
  # +cmd+:: logical command to run
  # +cmd_opts+:: hash of key:value arguments to use after the command
  def build_java_jar_command(jar, dashDProps, clazz, args_hash, cmd, cmd_opts={})
    command = "java "

    unless Params.env('DEBUG', '').empty?
      port = Params.env('DEBUG_PORT', 5005)
      suspend = ENV["DEBUG_SUSPEND"]
      puts " ------- Please connect to remote JVM at: #{port} (suspend: #{suspend})-------- "
      command << "-Xdebug -Xrunjdwp:server=y,transport=dt_socket,suspend=#{suspend},address=#{port} "
      ENV['DEBUG'] = nil if !(ENV['DISABLE_DEBUG_AFTER'].nil?)
    end

    command << "-jar #{jar} "

    command << "#{clazz} "

    dashD = Command.dashD(dashDProps)
    command << "#{dashD} "

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
