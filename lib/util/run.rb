
require "util/params"

module Run

  DEBUG = Params.env('DEBUG', '')

  def run(command)
     puts "Running: #{command}"
     `#{command}`
     raise "FAILED: '#{command}'" unless $? == 0
     $?
  end

  def java(jars_list, clazz, args_hash, cmd)
    debug = DEBUG.empty?? "" : "-Xdebug -Xrunjdwp:server=y,transport=dt_socket,address=5005,suspend=y"
    args = args_hash.map{|e| e.join(" ")}.join(" ")
    jars = jars_list.join(':')
    command = "java #{debug} -cp #{jars} #{clazz} #{args} #{cmd}"
    run command
  end
end
