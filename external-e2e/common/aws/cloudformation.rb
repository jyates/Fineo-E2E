
require 'aws'
require 'aws/credentials'

class Fineo::Aws::Cloudformation

  def initialize(credentials, verbose)
    @verbose = verbose
    creds = Fineo::Aws::Credentials.load(credentials)
    info = {
      access_key_id: creds['access_key_id'],
      secret_access_key: creds['secret_access_key'],
      validate_params: true,
      log_level: :debug
    }
    @client =  Aws::CloudFormation::Client.new(info)
  end

  def delete_stack(name)
    info = {stack_name: name}
    @client.delete_stack(info)
    @client.wait_until(:stack_delete_complete, info) do |waiter|
      waiter.max_attempts = nil
      waiter.delay = 15
    end
  end
end