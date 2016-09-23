
module Fineo
  module E2E
  end
end

require 'optparse'
require 'ostruct'

module Fineo::E2E::SettingUp

  def parse(args, name, info)
    options = OpenStruct.new(plans: [])
    OptionParser.new do |opts|
      opts.banner = "Usage: #{name} [options]"
      opts.separator info

      opts.on("--read-api-id API_ID", "ID of the read API") do |id|
        options.read = id
      end

      opts.on("--plan PLAN_ID", "ID of a usage plan to which we should add the key. REPEATABLE") do
      |plan|
        options.plans << plan
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
