module Tol
class Config
  require 'rainbow'
  require 'highline/import'
  
  require 'yaml'
  require 'etc'

  def self.read_config
    keys = ["collaborators", "awskey", "awssecret"]
    config = {}

    begin
      global = YAML::load(IO.read("/Users/#{Etc.getlogin}/tol.yml"))
      config.merge(global)
    rescue
    end

    begin
      local = YAML::load(IO.read("tol.yml"))
      config.merge(local)
    rescue
    end

    return config
  end

  def self.get_option(key)
    config = self.read_config
    return config[key]
  end
  
end
end