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
                    return nil
                end
            end

            # Delivers the message to +mailbox+
            # mailbox::
            #   A string containing the path of the mailbox to save
            #   the message to.  If it is of the form "=mailbox", it
            #   saves the message to +Maildir+/+mailbox+.  Otherwise,
            #   it simply saves the message to the file +mailbox+.
            def deliver_message(mailbox) 
                File.open(mailbox,"a") do |f|
                    f.flock(File::LOCK_EX)
                    f.seek(2)
                    message=(if f.tell > 0 then "\n" else "" end) + to_mbox
                    f.print message
                    f.flock(File::LOCK_UN)
                end
           end
        end
    end
end
