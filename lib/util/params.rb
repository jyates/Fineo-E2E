
module Params

  def self.env(str, default)
    a = ENV[str]
    a = default if a.nil? || a.empty?
    a
  end

  def self.env_require(str)
    a = ENV[str]
    raise "#{str} not defined in environment variables - it must be!" unless !a.nil?
    return a
  end

  WORKING_DIR = env('WORKING_DIR', 'tmp/')
end
