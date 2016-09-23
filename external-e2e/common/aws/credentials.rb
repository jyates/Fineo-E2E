
require 'aws'
require 'yaml'

module Fineo::Aws::Credentials

  def self.load(credentials_file)
    raise "No credentials file specified" if credentials_file.nil?
    begin
      creds = YAML.load(File.read(credentials_file))
    rescue Exception => e
      puts "Could not read credentials file at: #{credentials_file}"
      raise e
    end
    creds
  end
  def load_creds(credentials_file)
    Credentials.load(credentials_file)
  end
end
