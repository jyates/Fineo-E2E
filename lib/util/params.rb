
module Params

  def self.env(str, default)
    a = ENV['str']
    a = default if a.nil? || a.empty?
    a
  end

  WORKING_DIR = env('WORKING_DIR', 'tmp/')

end
