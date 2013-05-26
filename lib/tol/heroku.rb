module Tol
class Heroku
  def list_of_applications
    git_config = File.read(".git/config")
    git_config.scan(/heroku\..*:(.*)\.git/i).map do |result|
      result[0]
    end
  end
end
end