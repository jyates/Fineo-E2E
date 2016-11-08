
require 'e2e/state'
require 'util/params'

require 'resources/dynamo'
require 'resources/spark'
require 'resources/drill'
require 'resources/drill/base'

class E2ERunner

  def initialize
    @dynamo = Dynamo.new
    @steps = []
    @resources = [@dynamo]

    if File.exist? Params::WORKING_DIR
      out = "tmp-#{Random.new().rand(100000)}"
      FileUtils.mv(Params::WORKING_DIR, out)
      puts "Moved previous output to #{out}"
    end
  end

  def drill!(mode)
    case mode
      when "local"
        @drill = BaseDrill.new
      when "standalone"
        @drill = DrillResource.new
    end
    @resources << @drill
  end

  def schema!(org, metric, schema)
    @org = org
    @metric = metric
    @schema = schema
  end

  def events!(events)
    @events = events
    expected = []

    events.each{|event|
      d = event.dup
      # cleanup the event for what we actually expect to read back
      d.delete("companykey")
      d.delete("metrictype")
      expected << d
    }
    expected
  end


  def event!(event)
    events!([event])[0]
  end

  def create_schema
    @steps << lambda{ |e2e|
      puts
      puts " ----- Creating schema ------- "
      e2e.create_schema(@org, @metric, @schema)
    }
    self
  end

  def send_event
    @steps << lambda{ |e2e|
      puts
      puts " ----- Sending event ------- "
      e2e.send_event(@org, @metric, @events)
    }
    self
  end

  def batch_process
    @steps << lambda{ |e2e|
      puts
      puts " ----- Running batch processing ------- "
      e2e.batch_process(@spark)
    }
    # ok, we need to use spark
    @spark = Spark.new
    @resources << @spark
    self
  end

  def all_steps()
    puts "  --> Including all processing steps..."
    create_schema
    send_event
    batch_process
  end

  def run
    ensure_working_dir

    # ensure that we have some steps to run. Each step adds any additional resources (e.g. spark)
    all_steps if @steps.empty?

    @drill.org!(@org)
    @resources.each{|r|
      r.start unless r.nil?
    }

    e2e = E2EState.new(@dynamo, @drill)

    @steps.each{|step|
      step.call(e2e)
    }

    e2e
  end

  def cleanup
    @resources.each{|r|
      r.stop unless r.nil?
    }
  end

  def skip_batch_process_for_testing!
      self.create_schema().send_event()
      @spark = nil
  end

private

  def ensure_working_dir
    FileUtils.rm_rf Params::WORKING_DIR if Dir.exists?(Params::WORKING_DIR)
    Dir.mkdir Params::WORKING_DIR
  end
end
