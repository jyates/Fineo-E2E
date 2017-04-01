
module DrillComponent

  def with(mode, opts, batch_output_dir, dynamo_table_prefix)
    file_dir = "drill_read"
    unless @source.nil?
      file_dir = File.join(file_dir, @source)
    end
    file_dir = setup_dir(file_dir)

    @context = OpenStruct.new(:opts => opts,
          :batch => batch_output_dir,
          :prefix => dynamo_table_prefix,
          :dir => file_dir)
    @file = mode.call(@context)
    opts["--output"] = @file
    self
  end

  def read(org, metric)
    return read_sql(org, "SELECT * from #{getTableName(org, metric)} ORDER BY `timestamp` ASC")
  end

  def read_sql(org, sql)
    opts = @context.opts
    sql_file = "#{@file}.query"
    File.write(sql_file, sql)
    opts["--sql"] = sql_file
    opts["--org"] = org
    read_internal(@context)
    @file
  end

  # Much simpler implementation of reading from the cluster that goes through the simple query
  #'proxy'. Has to first bootstrap the cluster to include the expected tables, then makes a
  # simple http request and translates the results from JSON
  def read_proxy_sql(org, sql)
    raise "#{self.class} does not support proxy reads!" unless @supports_proxy

    opts = @context.opts
    opts["--org"] = org
    bootstrap(@context)

    require 'net/http'
    uri = URI("http://#{@cluster.proxy_host?}:#{@cluster.proxy_port?}/query")
    params = {
      :request => sql
    }
    uri.query = URI.encode_www_form(params)

    # Save the query
    query = "#{@file}.query"
    # random name so we don't clobber previous queries
    query = "#{query}-#{Random.new().rand(100000)}" if File.exists? query
    File.write(query, "Running query: #{sql} against #{uri}\n")

    # set the headers
    http = Net::HTTP.new(uri.host,uri.port)
    req = Net::HTTP::Post.new(uri.path, initheader = {'Content-Type' =>'application/json', 'x-api-key' => org})
    req.body = sql
  
    res = http.request(req)
    raise "Failed HTTP request! #{res}" unless res.is_a?(Net::HTTPSuccess)

    return JSON.parse(res.body)
  end
end
