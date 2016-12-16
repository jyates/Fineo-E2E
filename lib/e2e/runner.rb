
require 'e2e/state'
require 'util/params'

require 'resources/dynamo'
require 'resources/spark'
require 'resources/drill'
require 'resources/drill/base'
require 'pp'

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
        mode = "fineo-local"
        @drill = DrillResource.new
    end
    @drill_mode = mode
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
      puts " ----- Creating schema ------- "
      pp @schema
      e2e.create_schema(@org, @metric, @schema)
    }
    self
  end

  def send_event
    @steps << lambda{ |e2e|
      puts " ----- Sending event(s) ------- "
      pp @events
      e2e.send_event(@org, @metric, @events)
    }
    self
  end

  def batch_process
    @steps << lambda{ |e2e|
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

  def skip_ingest_validation()
    @skip_ingest_validation = true
    self
  end

  def clear_steps()
    @steps.clear()
  end

  def run(runner = nil)
    ensure_working_dir

    # ensure that we have some steps to run. Each step adds any additional resources (e.g. spark)
    all_steps if @steps.empty?

    if runner.nil?
      @drill.org!(@org)
      @resources.each{|r|
        r.start unless r.nil?
      }
      e2e = E2EState.new(@dynamo, @drill, @drill_mode, @skip_ingest_validation)
    else
      e2e = runner
    end

    @steps.each{|step|
      puts
      puts "`` Started #{Time.now}"
      step.call(e2e)
      puts "^^ Done #{Time.now}"
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
