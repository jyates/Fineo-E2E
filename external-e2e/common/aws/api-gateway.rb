
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

  def create_key(suffix="")
    puts "Creating key..." if @verbose
    @client.create_api_key(
      name: "[#{@id}] Test-Api: #{Time.now} - #{suffix}",
      enabled: true,
      )
  end

  def create_plan(api_id)
    puts "Creating usage plan for id: #{api_id}" if @verbose
    stages = api_id.map{|api|
        {
            api_id: api,
            stage: "prod"
        }
    }

    @client.create_usage_plan(
        name: "[#{@id}] Test Read Plan",
        description: "Plan to enable reading test apis",
        api_stages: stages
      )
  end

  def add_to_plan(id, key)
    puts "Adding key [#{key}] to plan: #{id}"
    @client.create_usage_plan_key(
        usage_plan_id: id,
        key_id: key,
        key_type: "API_KEY"
      )
  end

  def delete_key(id, strict=false)
    begin
      @client.delete_api_key(api_key: id)
    rescue Aws::APIGateway::Errors::NotFoundException => e
      raise e if strict
      puts "Could not delete key: #{id} - NOT FOUND!"
    end
  end

  def delete_plan(id, allow_stages=false)
    # get all the stages
    plan = @client.get_usage_plan(usage_plan_id: id)
    # convert them info remove requests
    ops = plan.api_stages.map{|stage|
      raise "No stages are allowed to be present in the plan! Found stages: #{plan.api_stages}" unless allow_stages
      {
        op: "remove",
        path: "/apiStages",
        value: "#{stage.api_id}:prod",
      }
    }

    # cleanup the existing stages
    if allow_stages
      # update the usage plan
      with_retry( lambda {
        @client.update_usage_plan(
          usage_plan_id: id,
          patch_operations: ops
        )
      })
    end

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
