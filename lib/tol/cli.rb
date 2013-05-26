require 'tol/database'

module Tol
class CLI
  require 'rainbow'

  def run
    if ARGV.length == 0
      help
    else
      case ARGV.first
      when "database"
        Tol::Database.new.run
      else
        help
      end
    end
  end

  def help
    puts "  #{"Take Off Labs".foreground(:green).underline} :: " +
         "#{"Collection of useful tools".underline}\n\n"

    database_help
    help_help
  end

  def database_help
    puts "  #{"tol database".foreground(:red)}    \# Copies the latest version of the database from Heroku to the local development system."
  end

  def help_help
    puts "  #{"tol help".foreground(:red)}        \# Displays this help message."
  end
end
end