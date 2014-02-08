require 'tol/config'

module Tol
class Newapp
  require 'rainbow'
  require 'highline/import'
  require 'aws-sdk'
  require 'fileutils'

  # TODO: Create real config file.
  # TODO: Save remotes in config file. Create command to add them to .git/config

  # Setup the buckets
  def awsbuckets
    puts Rainbow("Step 1. Creating AWS buckets").foreground(:green)

    puts "Please enter the name of the application:"
    name = STDIN.gets.gsub("\n", "")

    region = ""
    choose do |menu|
      menu.prompt = "Which region?"
      menu.choice "US Standard"             do region = "us-east-1" end
      menu.choice "US West (Oregon)"        do region = "us-west-2" end
      menu.choice "US West (N. California)" do region = "us-west-1" end
      menu.choice "EU (Ireland)"            do region = "eu-west-1" end
      menu.choice "Asia (Singapore)"        do region = "ap-southeast-1" end
      menu.choice "Asia (Sydney)"           do region = "ap-southeast-2" end
      menu.choice "Asia (Tokyo)"            do region = "ap-northeast-1" end
      menu.choice "S. America (Sao Paolo)"  do region = "sa-east-1" end
    end

    AWS.config(
      access_key_id:     Tol::Config.get_option("awskey"),
      secret_access_key: Tol::Config.get_option("awssecret"),
      region:            region
    )
  
    ["assets", "production", "development", "staging"].each do |suffix|
      create_bucket("#{name}-#{suffix}")
    end

    puts Rainbow("Step 2. Carrierwave").foreground(:green)

    choose do |menu|
      menu.prompt = "Using carrierwave?"
      menu.choice "Yes" do 
        create_carrierwave_config(name, region)
      
        # TODO: Add gem to gemfile automatically
        puts Rainbow("Add the following line to Gemfile").foreground(:green)
        puts "gem carrierwave"
        puts ""
      end

      menu.choice "No" do end
    end

    puts "Step 3. Asset Sync"

    choose do |menu|
      menu.prompt = "Using asset sync?"
      menu.choice "Yes" do
        create_asset_sync_config(name, region)

        # TODO: Add gem to gemfile automatically
        puts Rainbow("Add the following line to Gemfile").foreground(:green)
        puts "gem asset_sync"
        puts ""

        # TODO: Settings in production.rb, staging.rb automatically
        puts Rainbow("Add the following line to " + \
             "config/environments/production.rb").foreground(:green)
        puts "config.action_controller.asset_host = 'https://#{name}-assets.s3.amazonaws.com'"

        puts Rainbow("Add the following line to " + \
             "config/environments/staging.rb").foreground(:green)
        puts "config.action_controller.asset_host = 'https://#{name}-assets.s3.amazonaws.com'"
      end
      menu.choice "No"
    end
  end

  def create_bucket(name)
    puts Rainbow("Creating bucket #{name}").foreground(:yellow)
    s3 = AWS::S3.new
    bucket = s3.buckets.create(name)
    bucket.cors.set(
      :allowed_methods => %w(GET),
      :allowed_origins => %w(*),
      :max_age_seconds => 3600
    )
  end

  def create_carrierwave_config(name, region)
    aws_key    = Tol::Config.get_option("awskey")
    aws_secret = Tol::Config.get_option("awssecret")

    content = <<-eos
CarrierWave.configure do |config|
  config.fog_credentials = {
    provider:              'AWS',
    aws_access_key_id:     '#{aws_key}',
    aws_secret_access_key: '#{aws_secret}',
    region:                '#{region}'
  }
  config.fog_directory  = "#{name}-" + Rails.env
end
eos
    File.open("config/initializers/carrierwave.rb", "w") do |f|
      f.write(content)
    end
  end

  def create_asset_sync_config(name, region)
    aws_key    = Tol::Config.get_option("awskey")
    aws_secret = Tol::Config.get_option("awssecret")

    content = <<-eos
if defined?(AssetSync)
  AssetSync.configure do |config|
    config.fog_provider           = 'AWS'
    config.aws_access_key_id      = '#{aws_key}'
    config.aws_secret_access_key  = '#{aws_secret}'
    config.fog_directory          = "#{name}-assets"
    config.fog_region             = "#{region}"
  end
end
eos
    
    File.open("config/initializers/asset_sync.rb", "w") do |f|
      f.write(content)
    end
  end

  # New APP
  # Generate a new Heroku application
  def heroku
    puts Rainbow("Step 1. Create new Heroku application").foreground(:green)

    puts "Please enter the name of the new Heroku application:"
    name = STDIN.gets.gsub("\n", "")

    createapp = nil
    Bundler.with_clean_env do
      createapp = `heroku create #{name}`
    end

    if !createapp.include?("done, stack is cedar")
      puts createapp
      choose do |menu|
        menu.prompt = "Continue?"

        menu.choice "Yes" do 
        end
        
        menu.choice "No" do
          return
        end
      end
    end

    environment(name)
    collaborators(name)
    database(name)
    domains(name)
    email(name)
    asset_sync(name)
  end

  # Set up multi-environment system, if necessary (e.g., staging and production)
  def environment(app)
    choose do |menu|
      puts Rainbow("Step 2. Adding the Rails environment").foreground(:green)

      menu.prompt = "Which environment?"

      menu.choice "production" do
        Bundler.with_clean_env do
          system("heroku config:set RACK_ENV=production RAILS_ENV=production --app #{app}")
        end
      end

      menu.choice "staging" do
        Bundler.with_clean_env do
          system("heroku config:set RACK_ENV=staging RAILS_ENV=staging --app #{app}")
          system("cp config/environments/production.rb config/environments/staging.rb")
        end
      end
    end
  end

  # Adding collaborators
  def collaborators(app)
    choose do |menu|
      puts Rainbow("Step 3. Adding collaborators").foreground(:green)
      menu.prompt = "Which collaborators?"

      menu.choice "Default" do
        Tol::Config.get_option("collaborators").each do |email|
          Bundler.with_clean_env do
            system("heroku sharing:add #{email} --app #{app}")
          end
        end
      end

      menu.choice "No" do 
        puts "No problem!"
      end
      # TODO: Add a custom option, which allows entering more collaborators
      # from the console.
    end
  end

  # Adding database
  def database(app)
    choose do |menu|
      puts Rainbow("Step 4. Adding database addons").foreground(:green)
      menu.prompt = "Which database?"

      menu.choice "Postgres" do
        Bundler.with_clean_env do
          system("heroku addons:add heroku-postgresql:dev --app #{app}")
          system("heroku addons:add pgbackups:auto-month --app #{app}")
        end
      end

      menu.choice "None" do 
        puts "No problem!"
      end
    end
  end

  # Adding domains
  def domains(app)
    puts Rainbow("Step 5. Adding custom domains").foreground(:green)

    continue = true
    while continue do
      choose do |menu|
        menu.prompt = "Add another domain?"
        menu.choice "Yes" do
          puts "Enter domain (e.g., www.example.com, example.com, *.example.com):"
          domain = STDIN.gets.gsub("\n", "")
          Bundler.with_clean_env do
            system("heroku domains:add '#{domain}' --app #{app}")
          end
        end
        menu.choice "No" do 
          puts "No problem!"
          continue = false 
        end
      end
    end
  end

  # Adding email system
  def email(app)
    choose do |menu|
      puts Rainbow("Step 6. Adding email addons").foreground(:green)
      menu.prompt = "Which email system?"

      menu.choice "Mandrill" do
        Bundler.with_clean_env do
          system("heroku addons:add mandrill:starter --app #{app}")
        end

        puts Rainbow("Please paste " + \
             "and complete ").foreground(:green) + \
             "the following in your environment file (e.g., production.rb)"        
        content = <<-eos
config.action_mailer.default_url_options = { :host => 'http://<DOMAIN HERE>' }
config.action_mailer.delivery_method = :smtp
config.action_mailer.perform_deliveries = true
config.action_mailer.raise_delivery_errors = false
config.action_mailer.default :charset => "utf-8"
config.action_mailer.smtp_settings = {
  :port =>           '587',
  :address =>        'smtp.mandrillapp.com',
  :user_name =>      ENV['MANDRILL_USERNAME'],
  :password =>       ENV['MANDRILL_APIKEY'],
  :domain =>         '<DOMAIN HERE>',
  :authentication => :plain
}
eos
        puts content
      end

      menu.choice "Sendgrid" do
        Bundler.with_clean_env do
          system("heroku addons:add sendgrid:starter --app #{app}")
        end

        puts Rainbow("Please paste " + \
             "and complete ").foreground(:green) + \
             "the following in your environment file (e.g., production.rb)"
        content = <<-eos
config.action_mailer.default_url_options = { :host => 'http://<DOMAIN HERE>' }
config.action_mailer.delivery_method = :smtp
config.action_mailer.perform_deliveries = true
config.action_mailer.raise_delivery_errors = false
config.action_mailer.default :charset => "utf-8"
config.action_mailer.smtp_settings = {
  :address        => 'smtp.sendgrid.net',
  :port           => '587',
  :authentication => :plain,
  :user_name      => ENV['SENDGRID_USERNAME'],
  :password       => ENV['SENDGRID_PASSWORD'],
  :domain         => '<DOMAIN HERE>'
}
eos
        puts content
      end

      menu.choice "None" do 
        puts "No problem!"
      end
    end
  end

  # Enable asset sync
  def asset_sync(app)
    choose do |menu|
      puts Rainbow("Step 7. Adding Asset Sync").foreground(:green)
      menu.prompt = "Using Asset Sync?"

      menu.choice "Yes" do
        Bundler.with_clean_env do
          system("heroku labs:enable user-env-compile --app #{app}")
        end
      end

      menu.choice "No" do 
        puts "No problem!"
      end
    end
  end

  ### WWW Redirect
  def www_redirect
    content = <<-eos
class WwwMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)
    subdomains = request.host.split(".")
    if (subdomains[0] || "") != "www" && (subdomains[1] || "") != "herokuapp"
      [301, {"Location" => request.url.sub("//", "//www.")}, self]
    else
      @app.call(env)
    end
  end

  def each(&block)
  end
end
eos

    FileUtils.mkdir_p("lib/middleware")
    File.open("lib/middleware/www_middleware.rb", "w") do |f|
      f.write(content)
    end

    puts Rainbow("Add the following line to " + \
         "config/application.rb").foreground(:red)
    puts "config.autoload_paths += %W( \#\{ config.root \}/lib/middleware )"
    puts ""

    puts Rainbow("Add the following line to " + \
         "config/environments/production.rb").foreground(:red)
    puts "config.middleware.use \"WwwMiddleware\""
    puts ""
  end
end
end