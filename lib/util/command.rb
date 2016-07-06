
# Helper module for generating commands
module Command
  def self.spaces(args_hash)
     args_hash.map{|e| e.join(" ")}.join(" ")
  end
end
