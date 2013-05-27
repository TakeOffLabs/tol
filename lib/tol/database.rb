require 'tol/heroku'
require 'tol/rails_app'

module Tol
class Database
  require 'rainbow'
  require 'highline/import'

  def run
    puts "Identifying Heroku application"
    apps = Tol::Heroku.new.list_of_applications
    
    if apps.length == 0
      puts "No Heroku apps found".foreground(:red)
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

    puts "1. Detecting local database settings.".foreground(:yellow)
    @settings = Tol::RailsApp.new.database_settings["development"]

    puts "2. Capturing database on Heroku. Please wait.".foreground(:yellow)
    db = `heroku pgbackups:capture --app #{heroku_app} --expire`
    
    puts "3. Downloading. Please wait.".foreground(:yellow)
    url = `heroku pgbackups:url --app #{heroku_app}`
    download = `curl -o /tmp/#{heroku_app}.dump '#{url}' > /dev/null 2>&1`

    puts "4. Importing Database.".foreground(:yellow)
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

    puts "5. Cleaning up.".foreground(:yellow)
    clean_up = `rm /tmp/#{heroku_app}.dump`

    puts "DONE".foreground(:green)
  end

end
end