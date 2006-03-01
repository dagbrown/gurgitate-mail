#!/opt/bin/ruby -w

#------------------------------------------------------------------------
# Deliver mail to a maildir (also, detects maildir)
#------------------------------------------------------------------------

require "socket" # for gethostname (!)

module Gurgitate
    module Deliver
        module Maildir
            # Figures out if +mailbox+ is a Maildir mailbox
            # mailbox::
            #   A string containing the path of the mailbox to save the
            #   message to.  If it is of the form "=mailbox", it saves
            #   the message to +Maildir+/+mailbox+.  Otherwise, it
            #   simply saves the message to the file +mailbox+.
            def self::check_mailbox(mailbox)
                begin
                    if File.stat(mailbox).directory? then
                        if File.stat(File.join(mailbox,"cur")).directory? then
                            return Maildir
                        end
                    end
                rescue Errno::ENOENT
                    return nil
                end
            end

            # Figures out the first available filename in the mail dir
            # +dir+ and returns the filename to use.
            # dir::
            #   One of "+mailbox+/tmp" or "+mailbox+/new", but that's
            #   only because that's what the maildir spec
            #   (http://cr.yp.to/proto/maildir.html) says.
            def maildir_getfilename(dir)
                time=Time.now.to_f
                counter=0
                hostname=Socket::gethostname
                filename=nil
                loop do
                    filename=File.join(dir,sprintf("%.4f.%d_%d.%s",
                                                   time,$$,counter,hostname))
                    break if not File.exists?(filename)
                    counter+=1
                end
                return filename
            end

            # Creates a new Maildir folder +mailbox+
            # mailbox::
            #   The full path of the new folder to be created
            def make_mailbox(mailbox)
                Dir.mkdir(mailbox)
                %w{cur tmp new}.each do |dir|
                    Dir.mkdir(File.join(mailbox,dir))
                end
            end

            # Delivers a message to the maildir-format mailbox +mailbox+.
            # mailbox::
            #   A string containing the path of the mailbox to save the
            #   message to.  If it is of the form "=mailbox", it saves
            #   the message to +Maildir+/+mailbox+.  Otherwise, it
            #   simply saves the message to the file +mailbox+.
            def deliver_message(mailbox)
                begin
                    File.stat(mailbox)
                rescue Errno::ENOENT
                    make_mailbox(mailbox)
                end

                tmpfilename=maildir_getfilename(File.join(mailbox,"tmp"))
                File.open(tmpfilename,File::CREAT|File::WRONLY) do |fh|
                    fh.write(self.to_s)
                    fh.flush
                    # I should put a caveat here, unfortunately.  Ruby's
                    # IO#flush only flushes Ruby's buffers, not the
                    # operating system's.  If anyone knows how to force
                    # a real fflush(), I'd love to know.  Otherwise, I'm
                    # going to hope that closing the file does the trick
                    # for me.
                end

                # ...and link to new.
                # (I guess Maildir mailboxes don't work too well
                # on Windows, eh?)
                newfilename = maildir_getfilename(
                                        File.join(mailbox,"new"))
                begin
                    File.link(tmpfilename,newfilename)
                rescue SystemCallError
                    log("Couldn't create maildir link to \"new\"!")
                    exit 75 # Argh, I tried, it didn't work out
                end
                File.delete(tmpfilename)
            end
        end
    end
end
