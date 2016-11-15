
require 'aws'
require 'aws/credentials'

class Fineo::Aws::Dynamo
  def initialize(credentials, verbose)
    @verbose = verbose
    creds = Fineo::Aws::Credentials.load(credentials)
    @client = Aws::DynamoDB::Client.new(credentials: creds,
                                validate_params: true,
                                log_level: :debug)
  end

  def delete_tables_with_prefix(prefix)
    start = prefix
    while(!start.nil?)
    resp = @client.list_tables({
      exclusive_start_table_name: start
    })

    # go through each table. We get them in sorted order, so we're DONE when we find one that doesn't match the prefix
    resp.table_names.each{|table|
      return unless table.start_with? prefix
      puts "Deleting table: #{table}" if @verbose
      @client.delete_table(table_name: table)
    }

    # try with the next table
    start = resp.last_evaluated_table_name
  end
  end
end