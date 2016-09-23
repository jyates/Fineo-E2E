
module Fineo
  module E2E
  end
end

require 'optparse'
require 'ostruct'

module Fineo::E2E::Stacking

  def parse(args, name, info)
    options = OpenStruct.new(plans: [])
    OptionParser.new do |opts|
      opts.banner = "Usage: #{name} [options]"
      opts.separator info

      opts.on("--stack NAME", "Name of the cloudformation stack") do |name|
        options.name = name
      end

      opts.on('-c', '--credentials FILE', "Location of the credentials FILE to use.") do |s|
        options.credentials = s
      end

      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end

    end.parse!(args)

    options
  end
end
