
module JavaJars

  def self.find_aws_jars(path)
    JavaJars.find_jars(path, "aws")
  end

  def self.find_jars(path, suffix)
    absolute = File.absolute_path(path)
    jars = Dir.entries(absolute).delete_if{|file| !file.end_with?("#{suffix}.jar")}
    jars.map! {|jar| File.join(absolute, jar)}
    jars
  end
end
