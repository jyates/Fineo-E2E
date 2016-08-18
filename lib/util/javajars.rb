
module JavaJars

  def self.find_aws_jars(path)
    JavaJars.find_jars(path, "aws")
  end

  def self.find_jars(path, suffix)
    absolute = File.absolute_path(path)
    jars = JavaJars.find_jars_in(absolute, suffix)
    # target for cases when running locally against repos. Shouldn't be used in CI tools
    jars = JavaJars.find_jars_in(File.join(absolute, "target"), suffix) if jars.nil? || jars.empty?
    jars
  end

private
  def self.find_jars_in(absolute, suffix)
    jars = Dir.entries(absolute).delete_if{|file| !file.end_with?("#{suffix}.jar")}
    jars.map {|jar| File.join(absolute, jar)}
  end
end
