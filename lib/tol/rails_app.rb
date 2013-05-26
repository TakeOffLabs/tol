module Tol
class RailsApp
  def database_settings
    require 'yaml'
    settings = YAML.load_file("config/database.yml")
    settings
  end

end
end