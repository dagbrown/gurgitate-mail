#!/usr/bin/ruby -w

require "rbconfig"
require "ftools"

include Config

version = CONFIG["MAJOR"] + "." + CONFIG["MINOR"]
sitedir = CONFIG["sitedir"]
bindir  = CONFIG["bindir"]
dest    = "#{sitedir}/#{version}"

print "Installing gurgitate-mail.rb in #{dest}...\n"
File.install("gurgitate-mail.rb", dest, 0644)

print "Installing gurgitate-mail in #{bindir}...\n"

# Not so simple; need to put in the shebang line
from_f=File.open("gurgitate-mail")
to_f=File.open("#{bindir}/gurgitate-mail","w")
to_f.print("#!#{bindir}/ruby -w\n\n")
from_f.each do |l|
    to_f.print l
end

to_f.close()
from_f.close()

File.chmod(0755,"#{bindir}/gurgitate-mail")
