require 'tol/database'
require 'tol/codecheck'
require 'tol/newapp'
require 'tol/heroku'
require 'tol/git'

module Tol
class CLI
  require 'rainbow'

  def run
    if ARGV.length == 0
      help
    else
      case ARGV.first
      when "db"
        Tol::Database.new.run
      when "cm"
        Tol::Git.new.commit
      when "codecheck"
        Tol::Codecheck.new.run
      when "newapp:aws"
        Tol::Newapp.new.awsbuckets
      when "newapp:heroku"
        Tol::Newapp.new.heroku
      when "newapp:www"
        Tol::Newapp.new.www_redirect
      when "heroku:deploy"
        Tol::Heroku.new.deploy
      else
        help
      end
    end
  end

  def help
    puts "  #{Rainbow("Take Off Labs").foreground(:green).underline} :: " +
         "#{Rainbow("A collection of useful tools for Rails development").underline}\n\n"

    database_help
    git_help
    codecheck_help
    newapp_help
    heroku_help
    help_help
  end

  def database_help
    puts "  #{Rainbow("tol db").foreground(:red)}            \# Copies the latest version of the database from Heroku to the local development system."
  end
  
  def git_help
    puts "  #{Rainbow("tol cm").foreground(:red)}            \# Quick commit and push."
  end

  def codecheck_help
    puts "  #{Rainbow("tol codecheck").foreground(:red)}     \# Checks the code for left over binding.pry or console.log."
  end

  def newapp_help
    puts "  #{Rainbow("tol newapp:aws").foreground(:red)}    \# Set up Amazon Web Services S3 Buckets + (Carrierwave & Asset Sync)."
    puts "  #{Rainbow("tol newapp:heroku").foreground(:red)} \# Set up Heroku."
    puts "  #{Rainbow("tol newapp:www").foreground(:red)}    \# Set up a middleware that redirects non-www to www."
  end

  def heroku_help
    puts "  #{Rainbow("tol heroku:deploy").foreground(:red)} \# Deploy the app to Heroku."
  end

  def help_help
    puts "  #{Rainbow("tol help").foreground(:red)}          \# Displays this help message."
  end
end
end
