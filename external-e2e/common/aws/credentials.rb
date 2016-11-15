
require 'aws'
require 'yaml'

module Fineo::Aws::Credentials

  def self.load(credentials_file)
    begin
      creds = YAML.load(File.read(credentials_file))
    rescue Exception => e
      puts "Could not read credentials file at: #{credentials_file}" unless credentials_file.nil?
      return Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
    end
    creds
  end

  def load_creds(credentials_file)
    Credentials.load(credentials_file)
  end
end
