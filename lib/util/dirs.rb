
module Dirs

  def setup_dir(leaf_name)
    dir = File.join(Params::WORKING_DIR, leaf_name)
    FileUtils.mkpath(dir) unless Dir.exists?(dir)
    dir
  end
end
