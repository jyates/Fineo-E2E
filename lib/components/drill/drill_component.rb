
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
    opts = @context.opts
    opts["--org"] = org
    opts["--metric"] = metric

    read_internal(@context)
    @file
  end
end
