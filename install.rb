#!/usr/bin/ruby -w

require "rbconfig"
require "fileutils"

module Gurgitate
    Package = "gurgitate-mail"

    class Install
        def self.mkdir(d)
            print "Creating #{d}..."
            begin
                Dir.mkdir(d)
                print "\n"
            rescue Errno::EEXIST
                if FileTest.directory? d
                    puts "no need, it's already there."
                else
                    puts "there's something else there already."
                    raise
                end
            rescue Errno::ENOENT
                puts "its parent doesn't exist!"
                raise
            end
        end

        def self.install(prefix=nil)
            include Config

            if prefix then
                bindir = File.join prefix, "bin"; mkdir bindir
                dest   = File.join prefix, "lib"; mkdir dest
                mkdir File.join(prefix, "man")
                mandir = File.join prefix, "man", "man1"; mkdir mandir
            else
                version = CONFIG["MAJOR"] + "." + CONFIG["MINOR"]
                sitedir = CONFIG["sitedir"]
                bindir  = CONFIG["bindir"]
                mandir  = File.join(CONFIG["mandir"],"man1")
                dest    = CONFIG["sitelibdir"]
            end

            destgur = File.join(dest,"gurgitate")
            destdel = File.join(destgur,"deliver")

            print "Installing #{Package}.rb in #{dest}...\n"
            FileUtils.install("#{Package}.rb", dest, :mode => 0644)
            
            mkdir destgur
            Dir.glob(File.join("gurgitate","*.rb")).each { |f|
                puts "Installing #{f} in #{destgur}..."
                FileUtils.install(f,destgur)
            }

            mkdir destdel

            Dir.glob(File.join(File.join("gurgitate","deliver"),"*.rb")).each {
            |f|
                puts "Installing #{f} in #{destdel}..."
                FileUtils.install(f,destdel)
            }

            print "Installing #{Package}.1 in #{mandir}...\n"
            FileUtils.install("#{Package}.man","#{mandir}/#{Package}.1", 
                              :mode => 0644)

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
