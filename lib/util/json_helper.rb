
require 'json'

module JsonHelper

  def self.write(dir, name, data)
    # write the request to a json file
    ending = 0
    out = File.join(dir, "#{name}.json")
    # find a new ending for the command request file
    while(File.exists?(out)) do
      ending = ending +1
      out = "#{out}#{ending}"
    end

    Dir.mkdir dir unless Dir.exists? dir
    File.open(out,"w") do |f|
      f.write(data.to_json)
    end
    return out
  end
end
