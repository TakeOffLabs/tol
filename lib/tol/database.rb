require 'tol/heroku'
require 'tol/rails_app'
require 'bundler'

module Tol
class Database
  require 'rainbow'
  require 'highline/import'

  def run
    puts "Identifying Heroku application"
    apps = Tol::Heroku.new.list_of_applications
    
    if apps.length == 0
      puts "No Heroku apps found".foreground(:red)
      puts "Add your remotes to .git/config"
      # TODO: Automatically add remotes
    elsif apps.length == 1
      download(apps[0])
    else
      puts "Multiple Heroku apps found".foreground(:green)

      choose do |menu|
        menu.prompt = "Which database should I download?"
        apps.each do |app|
          menu.choice app do
            download(app)
          end
        end

        menu.choice "None"
      end
    end
  end

  def download(heroku_app)
    puts "Downloading database for #{heroku_app.underline}".foreground(:green)

    puts "Step 1. Detecting local database settings.".foreground(:yellow)
    @settings = Tol::RailsApp.new.database_settings["development"]

    choose do |menu|
      puts "Step 2. Which version of the database should I download?".foreground(:green)
      
      menu.prompt = "Please pick up database version?"
      
      local_file = "/tmp/#{heroku_app}.dump"
      if File.exists?(local_file)
        downloaded_at = File.mtime(local_file).strftime("%b %e, %l:%M %p")
        menu.choice "Local File (Fastest) - downloaded at #{downloaded_at}"
      end

      menu.choice "Most Recent Snapshot (Fast)" do
        puts "... Downloading. Please wait.".foreground(:yellow)
        url = ""
        Bundler.with_clean_env do
          url = `heroku pgbackups:url --app #{heroku_app}`
        end
        download = `curl -o /tmp/#{heroku_app}.dump '#{url}' > /dev/null 2>&1`
      end

      menu.choice "New Snapshot (Slowest)" do
        puts "... Capturing database on Heroku. Please wait".foreground(:yellow)
        db = ""
        Bundler.with_clean_env do
          db = `heroku pgbackups:capture --app #{heroku_app} --expire`
        end

        puts "... Downloading. Please wait.".foreground(:yellow)
        url = ""
        Bundler.with_clean_env do
          url = `heroku pgbackups:url --app #{heroku_app}`
        end
        
        download = `curl -o /tmp/#{heroku_app}.dump '#{url}' > /dev/null 2>&1`
      end
    end
    
    puts "Step 3. Importing Database.".foreground(:yellow)
    puts "-> drop old database"
    dropdb           = "dropdb"
    dropdb          += " -h #{@settings['host']}"      if @settings["host"]
    dropdb          += " -U #{@settings['username']}"  if @settings["username"]
    dropdb           = "PGPASSWORD=#{@settings['password']} " +
                       dropdb                          if @settings["password"]
    dropdb          += " #{@settings['database']}"
    drop             = `/bin/bash -c '#{dropdb}'`

    puts "-> recreate old database"
    createdb         = "createdb"
    createdb        += " -h #{@settings['host']}"      if @settings["host"]
    createdb        += " -U #{@settings['username']}"  if @settings["username"]
    createdb         = "PGPASSWORD=#{@settings['password']} " +
                       createdb                        if @settings["password"]
    createdb        += " #{@settings['database']}"
    create           = `/bin/bash -c '#{createdb}'`

    puts "-> restore from file"
    restore_command  = "pg_restore --verbose --clean --no-acl --no-owner"
    restore_command += " -d #{@settings['database']}"
    restore_command += " -h #{@settings['host']}"      if @settings["host"]
    restore_command += " -U #{@settings['username']}"  if @settings["username"]
    restore_command  = "PGPASSWORD=#{@settings['password']} " +
                       restore_command                 if @settings["password"]
    restore_command += " /tmp/#{heroku_app}.dump > /dev/null 2>&1"
    restore          = `/bin/bash -c '#{restore_command}'`

    puts "DONE".foreground(:green)
  end

end
end