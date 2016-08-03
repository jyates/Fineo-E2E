
require 'e2e/state'

require 'resources/dynamo'
require 'resources/spark'
require 'resources/drill'
require 'resources/drill/base'

class E2ERunner

  def initialize
    @dynamo = Dynamo.new
    @spark = Spark.new
    @steps = []
  end

  def drill!(mode)
    case mode
      when "local"
        @drill = BaseDrill.new
      when "standalone"
        @drill = DrillResource.new
    end
  end

  def schema!(org, metric, schema)
    @org = org
    @metric = metric
    @schema = schema
  end

  def event!(event)
    @event = event
    expected = event.dup

    # cleanup the event for what we actually exepct to read back
    expected.delete("companykey")
    expected.delete("metrictype")
    expected
  end

  def create_schema
    @steps << lambda{ |e2e|
      e2e.create_schema(@org, @metric, @schema)
    }
    self
  end

  def send_event
    @steps << lambda{ |e2e|
      e2e.send_event(@org, @metric, @event)
    }
    self
  end

  def batch_process
    @steps << lambda{ |e2e|
      e2e.batch_process
    }
    self
  end

  def all_steps()
    create_schema
    send_event
    batch_process
  end

  def run
    ensure_working_dir
    @resources = [@dynamo, @spark, @drill]
    @resources.each{|r|
      r.start
    }

    e2e = E2EState.new(@dynamo, @spark, @drill)

    all_steps if @steps.empty?

    @steps.each{|step|
      step.call(e2e)
    }


    # setup the event we want to send
    #e2e.create_schema(@org, @metric, @schema)

    #e2e.send_event(@org, @metric, @event)

    # convert to parquet and correct directory structure
    #e2e.batch_process

    e2e
  end

  def cleanup
    @resources.each{|r|
      r.stop
    }
  end

private

  def ensure_working_dir
    FileUtils.rm_rf Params::WORKING_DIR if Dir.exists?(Params::WORKING_DIR)
    Dir.mkdir Params::WORKING_DIR
  end
end
