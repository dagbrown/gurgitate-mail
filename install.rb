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
            dest    = File.join(sitedir,version)
            destgur = File.join(dest,"gurgitate")
            destdel = File.join(destgur,"deliver")

            print "Installing #{Package}.rb in #{dest}...\n"
            File.install("#{Package}.rb", dest, 0644)
            
            print "Creating #{destgur}..."
            begin
                Dir.mkdir(destgur)
                print "\n"
            rescue Errno::EEXIST
                puts "no need, it's already there."
            end
            Dir.glob(File.join("gurgitate","*.rb")).each { |f|
                puts "Installing #{f} in #{destgur}..."
                File.install(f,destgur)
            }

            print "Creating #{destdel}..."
            begin
                Dir.mkdir(destdel)
                print "\n"
            rescue Errno::EEXIST
                puts "no need, it's already there."
            end
            Dir.glob(File.join(File.join("gurgitate","deliver"),"*.rb")).each {
            |f|
                puts "Installing #{f} in #{destdel}..."
                File.install(f,destdel)
            }

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
