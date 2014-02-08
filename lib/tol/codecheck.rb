require 'tol/heroku'
require 'tol/rails_app'

module Tol
class Codecheck
  require 'rainbow'
  require 'highline/import'

  attr_accessor :terminal_columns

  def run
    size = HighLine::SystemExtensions.terminal_size
    self.terminal_columns = size[0]

    check_for_binding_pry
    check_for_console_log
  end

  def check_for_binding_pry    
    puts Rainbow("Checking for binding.pry").foreground(:yellow)
    result = `find . -name "*.rb" -exec grep -H "binding.pry" {} \\\;`
    if result.length > 0
      puts Rainbow("The following binding.pry's have been found").foreground(:red)
      result.split("\n").each do |res|
        puts res[0..self.terminal_columns - 2]
      end
      puts Rainbow("Please fix").foreground(:red)
    else
      puts Rainbow("No binding.pry's found").foreground(:green)
    end
  end

  def check_for_console_log
    puts Rainbow("Checking for console.log").foreground(:yellow)
    result = `find . -name "*.js*" -exec grep -H "console.log" {} \\\;`
    if result.length > 0
      puts Rainbow("The following console.log's have been found").foreground(:red)
      result.split("\n").each do |res|
        puts res[0..self.terminal_columns - 2]
      end
      puts Rainbow("Please fix!").foreground(:red)
    else
      puts Rainbow("No console.log's found").foreground(:green)
    end
  end
end
end