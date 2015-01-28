require 'tol/heroku'

module Tol
class Git
  require 'rainbow'
  require 'highline/import'

  attr_accessor :terminal_columns

  def initialize
    size = HighLine::SystemExtensions.terminal_size
    self.terminal_columns = size[0]
  end
  
  def commit
    puts Rainbow("Committing").foreground(:green)
    
    category = nil
    icon = nil
    choose do |menu|
      menu.prompt = "Category:"
      
      menu.choice "Bug" do 
        category = "bug"
        icon = ":heavy_exclamation_mark:"
      end

      menu.choice "Enhancement" do
        category = "enhancement"
        icon = ":lipstick:"
      end
      
      menu.choice "Feature" do
        category = "feature"
        icon = ":rocket:"
      end
      
      menu.choice "WIP" do
        category = "wip"
        icon = ":construction:"
      end
      
      menu.choice "Performance" do
        category = "performance"
        icon = ":racehorse:"
      end
      
      menu.choice "Housekeeping" do
        category = "housekeeping"
        icon = ":wrench:"
      end
      
      menu.choice "Cleanup (Code Deletion)" do
        category = "cleanup"
        icon = ":bathtub:"
      end
    end
    
    puts "Message: "
    message = STDIN.gets.gsub("\n", "")
    
    branch = `git rev-parse --abbrev-ref HEAD`.gsub("\n", "")
    
    message = "#{icon} #{message}"
    
    `git add -u .`
    `git commit -m '#{message}'`
    `git push origin #{branch}`
  end

end
end
