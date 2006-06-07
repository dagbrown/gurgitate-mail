#------------------------------------------------------------------------
# Mail filter invocation script
#------------------------------------------------------------------------

require "gurgitate-mail"
require 'optparse'

# change this on installation to taste
GLOBAL_RULES="/etc/gurgitate-rules"
GLOBAL_RULES_POST="/etc/gurgitate-rules-default"

commandline_files = []

opts = OptionParser.new do |o|
  o.on("-f FILE", "--file FILE", "Use FILE as a rules file") do |file|
    commandline_files << file
  end
  o.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end

opts.parse!(ARGV)

gurgitate = Gurgitate::Gurgitate.new(STDIN)

if commandline_files.length > 0
  commandline_files.each do |file|
    gurgitate.add_rules(file, :user => true)
  end
else
  gurgitate.add_rules(GLOBAL_RULES, :system => true)
  gurgitate.add_rules(:default)
  gurgitate.add_rules(GLOBAL_RULES_POST, :system => true)
end

gurgitate.process
