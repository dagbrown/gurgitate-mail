#!/usr/bin/ruby -w

require "rbconfig"
require "ftools"

module Gurgitate
    Package = "gurgitate-mail"

    class Install
        def Install.install()
            include Config

            version = CONFIG["MAJOR"] + "." + CONFIG["MINOR"]
            sitedir = CONFIG["sitedir"]
            bindir  = CONFIG["bindir"]
            mandir  = CONFIG["mandir"] + "/man1"
            dest    = "#{sitedir}/#{version}"

            print "Installing #{Package}.rb in #{dest}...\n"
            File.install("#{Package}.rb", dest, 0644)

            print "Installing #{Package}.1 in #{mandir}...\n"
            File.install("#{Package}.man","#{mandir}/#{Package}.1", 0644)

            print "Installing #{Package} in #{bindir}...\n"
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
        end
    end
end

if __FILE__ == $0 then
    Gurgitate::Install.install()
end
