
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
end
