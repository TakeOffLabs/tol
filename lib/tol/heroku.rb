require 'tol/config'
require 'bundler'

module Tol
class Heroku
  require 'rainbow'
  require 'highline/import'

  def list_of_applications
    git_config = File.read(".git/config")
    git_config.scan(/heroku\..*:(.*)\.git/i).map do |result|
      result[0]
    end
  end

  def deploy
    puts "Deploying to Heroku".foreground(:green)

    puts "Identifying git branch"
    branch = `git rev-parse --abbrev-ref HEAD`.gsub("\n", "")

    puts "Identified local branch #{branch.foreground(:green)}. Please confirm."
    choose do |menu|
      menu.prompt = "Continue?"
      
      menu.choice "Yes" do 
      end

      menu.choice "No" do
        return
      end
    end

    puts "Identifying Heroku application"
    apps = list_of_applications    
    if apps.length == 0
      puts "No Heroku apps found".foreground(:red)
      puts "Add your remotes to .git/config"
      # TODO: Automatically add remotes
    elsif apps.length == 1
      deploy_to(apps[0], branch)
    else
      puts "Multiple Heroku apps found".foreground(:green)

      choose do |menu|
        menu.prompt = "Where to deploy?"
        apps.each do |app|
          menu.choice app do
            deploy_to(app, branch)
          end
        end

        menu.choice "None"
      end
    end
  end

  def deploy_to(remote, branch)
    Bundler.with_clean_env do
      system("git push -f #{remote} #{branch}:master")
      system("heroku run rake db:migrate --remote #{remote}")
      system("heroku restart --remote #{remote}")
    end
  end
end
end