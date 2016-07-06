
require "util/params"
require "util/command"

module Run

  def run(command, log=true)
     puts "Running: #{command}" if log
     `#{command}`
     raise "FAILED: '#{command}'" unless $? == 0
     $?
  end

  def java(jars_list, clazz, args_hash, cmd, cmd_opts={})
    command = "java "

    unless Params.env('DEBUG', '').empty?
      command.concat "-Xdebug -Xrunjdwp:server=y,transport=dt_socket,address=5005,suspend=y "
    end

    jars = jars_list.join(':')
    raise "No jars found for class: #{clazz}!" if jars.empty?
    command.concat "-cp #{jars} "

    command.concat "#{clazz} "

    args = Command.spaces(args_hash)
    command.concat "#{args} "

    cmd.concat " #{Command.spaces(cmd_opts)}" unless cmd_opts.empty?
    command.concat "#{cmd} >> tmp/out.log 2>> tmp/error.log"

    run("echo ---- #{clazz} ----- >> tmp/out.log ", false)
    run("echo ---- #{clazz} ----- >> tmp/error.log ", false)
    run command
  end
end
