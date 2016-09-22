
require 'aws'
require 'aws/credentials'

class Fineo::Aws::ApiGateway

  def initialize(credentials, verbose)
    @verbose = verbose
    creds = Fineo::Aws::Credentials.load(credentials)
    @client = Aws::APIGateway::Client.new(access_key_id: creds['access_key_id'],
                                secret_access_key: creds['secret_access_key'],
                                validate_params: true,
                                log_level: :debug)
    @id = Random.new().rand(1000000)
  end

  def create_key()
    puts "Creating key..." if @verbose
    @client.create_api_key(
      name: "[#{@id}] Test-Api: #{Time.now}",
      enabled: true,
      )
  end

  def create_plan(api_id)
    puts "Creating usage plan for id: #{api_id}" if @verbose
    @client.create_usage_plan(
        name: "[#{@id}] Test Read Plan - #{api_id}",
        description: "Plan to support reading api: #{api_id}",
        api_stages: [
          {
            api_id: api_id,
            stage: "prod"
          }
        ]
      )
  end

  def add_to_plan(id, key)
    puts "Adding key [#{key.id} - #{key.name}] to plan: #{id}"
    @client.create_usage_plan_key(
        usage_plan_id: id,
        key_id: key.id,
        key_type: "API_KEY"
      )
  end
end
