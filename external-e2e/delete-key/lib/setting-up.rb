
module Fineo
  module E2E
  end
end

require 'optparse'
require 'ostruct'
require 'json'

module Fineo::E2E::SettingUp

  def parse(args, name, info)
    options = OpenStruct.new
    OptionParser.new do |opts|
      opts.banner = "Usage: #{name} [options]"
      opts.separator info

      opts.on("--setup-props PROPERTIES", "JSON properties from the setup phase") do |setup|
        options.info = JSON.parse(File.read(setup))
      end

      opts.on('-c', '--credentials FILE', "Location of the credentials FILE to use.") do |s|
        options.credentials = s
      end

      opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
        options.verbose = v
      end

      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end

    end.parse!(args)

    options
  end
end
