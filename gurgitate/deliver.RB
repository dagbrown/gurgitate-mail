#!/opt/bin/ruby -w

#------------------------------------------------------------------------
# Code to handle saving a message to a mailbox (and a framework for detecting
# what kind of mailbox it is)
#------------------------------------------------------------------------

require "gurgitate/deliver/mbox"
require "gurgitate/deliver/maildir"

module Gurgitate::Deliver
    # Saves a message to +mailbox+, after detecting what the mailbox's
    # format is.
    # mailbox::
    #   A string containing the path of the mailbox to save
    #   the message to.  If it is of the form "=mailbox", it
    #   saves the message to +Maildir+/+mailbox+.  Otherwise,
    #   it simply saves the message to the file +mailbox+.
    def save(mailbox)
        if mailbox[0,1]=='=' and @maildir != nil
            mailbox["="]=@maildir+"/"
        end

        if mailbox[0,1] != '/'
            log("Cannot save to relative filenames!  Saving to spool file");
            mailbox=spoolfile
        end

        # detect the kind of folder
        [Gurgitate::Deliver::MBox,Gurgitate::Deliver::Maildir].each do |mod|
            if mod::check_mailbox(mailbox) then
                include mod
                break
            end
        end

        log("Saving to mailbox "+mailbox)

        begin
            deliver_message(mailbox)
        rescue SystemCallError
            log("Gack!  Something went wrong: " + $!)
            exit 75
        end
    end
end
