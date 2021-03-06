#!/opt/bin/ruby -w
# -*- encoding : utf-8 -*-

#------------------------------------------------------------------------
# Code to handle saving a message to a mailbox (and a framework for detecting
# what kind of mailbox it is)
#------------------------------------------------------------------------

require "gurgitate/deliver/mbox"
require "gurgitate/deliver/maildir"
require "gurgitate/deliver/mh"

module Gurgitate
    module Deliver

        class MailboxFound < Exception
            # more of a "flag" than an exception really
        end

        # Saves a message to +mailbox+, after detecting what the mailbox's
        # format is.
        # mailbox::
        #   A string containing the path of the mailbox to save
        #   the message to.  If it is of the form "=mailbox", it
        #   saves the message to +Maildir+/+mailbox+.  Otherwise,
        #   it simply saves the message to the file +mailbox+.
        def save(mailbox)

            if mailbox[0,1]=='=' and @maildir != nil then
                if @folderstyle == Maildir and mailbox !~ /^=\./ then
                    mailbox["="]=@maildir+"/."
                else
                    mailbox["="]=@maildir+"/"
                end
            end

            if mailbox[0,1] != '/' then
                log("Cannot save to relative filenames!  Saving to spool file");
                mailbox=spoolfile
            end

            begin
                [MBox,Maildir,MH].each do |mod|
                    if mod::check_mailbox(mailbox) then
                        extend mod
                        raise MailboxFound
                    end
                end

                # Huh, nothing could find anything.  Oh well,
                # let's default to whatever's in @folderstyle.  (I
                # guess we'll be making a new mailbox, eh?)

                if Module === @folderstyle then
                    #
                    # Careful we don't get the wrong instance variable 
                    folderstyle=@folderstyle 

                    extend folderstyle
                else
                    # No hints from the user either.  Let's guess!
                    # I'll use the same heuristic that Postfix uses--if the
                    # mailbox name ends with a /, then make it a Maildir,
                    # otherwise make it a mail file
                    if mailbox =~ /\/$/ then
                        extend Maildir
                    else
                        extend MBox
                    end
                end
                
            rescue MailboxFound
                # Don't need to do anything--we only have to worry
                # about it if there wasn't a mailbox there.
                nil
            end

            begin
                deliver_message(mailbox)
            rescue SystemCallError
                self.log "Gack!  Something went wrong: " + $!.to_s
                raise
                # exit 75
            end
        end
    end
end
