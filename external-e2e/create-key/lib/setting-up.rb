
module Fineo
  module E2E
  end
end

require 'aws-sdk'
require 'optparse'
require 'ostruct'

module Fineo::E2E::SettingUp

  def parse(args)
    options = OpenStruct.new
    OptionParser.new do |opts|
      opts.banner = "Usage: setup-key [options]"
      opts.separator "Set up an API key for E2E testing"

      opts.on("--read-api-id API_ID", "ID of the read API") do |id|
        options.read = id
      end

      opts.on("--schema-usage-plan PLAN_ID", "ID of the schema usage plan") do |plan|
        options.schema = plan
      end

      opts.on("--write-usage-plan PLAN_ID", "ID of the write usage plan") do |plan|
        options.write = plan
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
