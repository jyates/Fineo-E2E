
module JavaJars

  def self.find_aws_jars(path)
    JavaJars.find_jars(path, "aws")
  end

  def self.find_jars(path, suffix)
    absolute = File.absolute_path(path)
    jars = JavaJars.find_jars_in(absolute, suffix)
    dir = File.join(absolute, "target")
    jars = JavaJars.find_jars_in(dir, suffix) if (jars.nil? || jars.empty?) && Dir.exists?(dir)
    jars
  end

private
  def self.find_jars_in(absolute, suffix)
    jars = Dir.entries(absolute).delete_if{|file| !file.end_with?("#{suffix}.jar")}
    jars.map {|jar| File.join(absolute, jar)}
  end
end
