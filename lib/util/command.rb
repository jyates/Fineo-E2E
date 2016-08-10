
# Helper module for generating commands
module Command
  def self.spaces(args_hash)
     args_hash.map{|k,v|
        k if v.nil?
        "#{k} #{v}"
     }.join(" ")
  end
end
