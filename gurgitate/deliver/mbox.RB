#!/opt/bin/ruby -w

#------------------------------------------------------------------------
# Delivers a message to an mbox (also includes mbox detector)
#------------------------------------------------------------------------

module Gurgitate
    module Deliver
        module MBox
            # Checks to see if +mailbox+ is an mbox mailbox
            # mailbox::
            #   A string containing the path of the mailbox to save
            #   the message to.  If it is of the form "=mailbox", it
            #   saves the message to +Maildir+/+mailbox+.  Otherwise,
            #   it simply saves the message to the file +mailbox+.
            def self::check_mailbox(mailbox)

                if File.stat(mailbox).file? then 
                    return MBox
                else
                    if File.exists? mailbox
                        return nil
                    else
                        return MBox
                    end
                end
            end

            # Delivers the message to +mailbox+
            # mailbox::
            #   A string containing the path of the mailbox to save
            #   the message to.  If it is of the form "=mailbox", it
            #   saves the message to +Maildir+/+mailbox+.  Otherwise,
            #   it simply saves the message to the file +mailbox+.
            def deliver_message(mailbox) 
                File.open(mailbox,File::WRONLY | 
                                  File::APPEND | 
                                  File::CREAT) do |f|
                    f.flock(File::LOCK_EX)
                    message=(if f.stat.size > 0 then "\n" else "" end) + to_mbox
                    f.print message
                    f.flock(File::LOCK_UN)
                end
           end
        end
    end
end
