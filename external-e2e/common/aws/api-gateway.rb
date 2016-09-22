
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

  def delete_key(id)
    begin
      @client.delete_api_key(api_key: id)
    rescue Aws::APIGateway::Errors::NotFoundException
      puts "Could not delete key: #{id} - NOT FOUND!"
    end
  end

  def delete_plan(id)
    # get all the stages
    plan = @client.get_usage_plan(usage_plan_id: id)
    # convert them info remove requests
    ops = plan.api_stages.map{|stage|
      {
        op: "remove",
        path: "/apiStages",
        value: "#{stage.api_id}:prod",
      }
    }

    # update the usage plan
    with_retry( lambda {
      @client.update_usage_plan(
        usage_plan_id: id,
        patch_operations: ops
      )
    })

    # delete the plan now that its empty
    with_retry( lambda {
      @client.delete_usage_plan(usage_plan_id: id)
      })
  end

private

  def with_retry(proc, index=1)
    raise "Could not complete action within #{index} attempts" if index > 7
    begin
      proc.call
    rescue Aws::APIGateway::Errors::TooManyRequestsException => e
      time = 30 * index
      time = [time, 90].min
      puts "   request failed, retrying in #{time} seconds"
      sleep(time)
      with_retry(proc, index +1)
    end
  end
end
