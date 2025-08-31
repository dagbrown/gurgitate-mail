#!/opt/bin/ruby -w

require "yaml"

#------------------------------------------------------------------------
# Delivers a message to an mbox (also includes mbox detector)
#------------------------------------------------------------------------

module Gurgitate
    module Deliver
        module MH
            # Checks to see if +mailbox+ is an mbox mailbox
            # mailbox::
            #   A string containing the path of the mailbox to save
            #   the message to.  If it is of the form "=mailbox", it
            #   saves the message to +Maildir+/+mailbox+.  Otherwise,
            #   it simply saves the message to the file +mailbox+.
            def self::check_mailbox mailbox
                begin
                    # Rather annoyingly, pretty well any directory can
                    # be a MH mailbox, but this just checks to make sure
                    # it's not actually a Maildir by mistake.
                    #
                    # I could put in a check for the path given in
                    # $HOME/.mh_profile, but Claws-Mail uses MH mailboxes and
                    # disregards $HOME/.mh_profile.
                    if( File.stat(mailbox).directory? and
                        not ( File.exist?(File.join(mailbox, "cur")) or
                              File.exist?(File.join(mailbox, "tmp")) or
                              File.exist?(File.join(mailbox, "new")) ) ) then
                        return MH
                    end
                rescue Errno::ENOENT
                    return nil
                end
            end

            # Delivers the message to +mailbox+
            # mailbox::
            #   A string containing the path of the mailbox to save
            #   the message to.  If it is of the form "=mailbox", it
            #   saves the message to +Maildir+/+mailbox+.  Otherwise,
            #   it simply saves the message to the file +mailbox+.
            def deliver_message mailbox
                if ! File.exist? mailbox then
                    Dir.mkdir(mailbox)
                end

                if File.exist? mailbox and not File.directory? mailbox then
                    raise SystemError, "not a directory"
                end

                new_msgnum = next_message(mailbox) do |filehandle|
                    filehandle.print self.to_s
                end

                update_sequences(mailbox, new_msgnum)
            end

            private

            def update_sequences mailbox, msgnum
                sequences = File.join(mailbox, ".mh_sequences")
                lockfile = sequences + ".lock" # how quaint
                counter=0
                while counter < 10 do
                    begin
                        File.open(lockfile,
                                  File::WRONLY |
                                  File::CREAT |
                                  File::EXCL ) do |lock|
                            File.open(sequences,
                                      File::RDWR | File::CREAT) do |seq|

                                seq.flock(File::LOCK_EX)
                                metadata = YAML.load(seq.read) || Hash.new

                                metadata["unseen"] = update_unseen \
                                    metadata["unseen"], msgnum

                                seq.rewind
                                metadata.each do |key, val|
                                    seq.puts "#{key}: #{val}"
                                end
                                seq.truncate seq.tell
                                seq.flock(File::LOCK_UN)
                            end
                        end

                        File.unlink lockfile
                        break
                    rescue Errno::EEXIST
                        # some other process is doing something, so wait a few
                        # milliseconds until it's done
                        counter += 1
                        sleep(0.1)
                    end
                end

                # If it's still around after 10 tries, then obviously 
                # something bigger went wrong; forcibly remove it and
                # try again.
                if counter == 10 then
                    File.unlink lockfile
                    update_sequences mailbox, msgnum
                end
            end

            def update_unseen unseen, msgnum
                prevmsg = msgnum - 1
                if unseen
                    unseenstring = unseen.to_s

                    if unseenstring =~ /-#{prevmsg}/ then
                        return unseenstring.sub(/\b#{prevmsg}\b/, msgnum.to_s)
                    end

                    if unseenstring.match(/\b#{prevmsg}\b/) then
                        return "#{unseenstring}-#{msgnum}"
                    end

                    return "#{unseenstring} #{msgnum}"
                else
                    return msgnum
                end
            end

            def next_message mailbox
                next_msgnum = Dir.open(mailbox).map { |ent| ent.to_i }.max + 1
                loop do
                    begin
                        File.open(File.join(mailbox, next_msgnum.to_s),
                                  File::WRONLY |
                                  File::CREAT |
                                  File::EXCL ) do |filehandle|
                            yield filehandle
                        end
                        break
                    rescue Errno::EEXIST
                        next_msgnum += 1
                    end
                end
                return next_msgnum
            end
        end
    end
end
