
module JavaJars
  def self.find_aws_jars(absolute)
    jars = Dir.entries(absolute).delete_if{|file| !file.end_with?("aws.jar")}
    jars.map! {|jar| File.join(absolute, jar)}
    jars
  end
end
