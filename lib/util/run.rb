
require "util/params"

module Run

  def run(command, log=true)
     puts "Running: #{command}" if log
     `#{command}`
     raise "FAILED: '#{command}'" unless $? == 0
     $?
  end

  def java(jars_list, clazz, args_hash, cmd)
    debug_set = Params.env('DEBUG', '')
    debug = debug_set.empty?? "" : "-Xdebug -Xrunjdwp:server=y,transport=dt_socket,address=5005,suspend=y"
    args = args_hash.map{|e| e.join(" ")}.join(" ")
    jars = jars_list.join(':')
    raise "No jars found for class: #{clazz}!" if jars.empty?
    run("echo ---- #{clazz} ----- >> tmp/out.log", false)
    command = "java #{debug} -cp #{jars} #{clazz} #{args} #{cmd} >> tmp/out.log"
    run command
  end
end
