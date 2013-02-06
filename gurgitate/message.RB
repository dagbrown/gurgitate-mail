#!/opt/bin/ruby -w
# -*- encoding : utf-8 -*-

#------------------------------------------------------------------------
# Handles a complete mail message
#------------------------------------------------------------------------

require 'gurgitate/mail_headers'

module Gurgitate

    # A complete mail message.
    class Message

        # The headers of the message
        attr_reader :headers
        # The body of the message
        attr_accessor :body

        # Creates a new message from the options hash, and the body of the
        # message in a string.
        #
        # This can actually be invoked in several ways:
        #
        #    Gurgitate::Mailmessage.create "This is the message body",
        #       :from    => "from_address@example.com",
        #       :to      => "to_address@example.com",
        #       :subject => "This is the message subject"
        #
        # This results in an email message that, when rendered via to_s, will
        # look like this:
        #
        #   From: from_address@example.com
        #   To: to_address@example.com
        #   Subject: This is the message subject
        #
        #   This is the message body
        #
        # If you prefer to do things entirely by options hashes, as some do,
        # you can substitute a :body key for the first argument:
        #
        #    Gurgitate::Mailmessage.create(
        #        :body    => "This is the message body",
        #        :from    => "from_address@example.com",
        #        :to      => "to_address@example.com",
        #        :subject => "This is the message subject"
        #    )
        #
        # There are two other special options you can use: :sender and
        # :recipient.  These are used to specify the sender and recipient of
        # email messages, when the message is sent via SMTP.
        #
        def self.create(*args)
            options = body = nil

            if String === args[0]
                options = args[1]
                body = args[0]
            elsif Hash === args[0]
                options = args[0]
            else
                options = {}
            end

            message = self.new

            message.instance_eval do
                if body
                    @body=body
                end

                @headers = Headers.new(options)
            end

            message
        end

        # Creates a new Gurgitate message from a pre-existing message.
        # This is what is used when gurgitate-mail is used as a mail filter.
        #
        # ARGUMENTS::
        # +text+      :: An RFC822-formatted message.
        # +recipient+ :: The recipient of the email message, from the MTA
        # +sender+    :: The sender of the email message, also from the MTA
        #
        # All of its arguments can be nil: if called with no arguments,
        # it simply returns an empty email message, which can be populated
        # after the fact.
        def initialize(text=nil)
            if text
                (@headertext,@body)=text.split(/\n\n/,2)
                @headers=Headers.new(@headertext);
            else
                @headers = Headers.new
                @body = ""
            end
        end

        # Returns the header +name+, which is, note, a HeaderBag of all
        # headers by that name, not just a single header.
        #
        # If you want the text of the header, then you have to coerce it to a
        # string:
        #
        #    header("name").to_s
        #
        def header(name)
            @headers[name].each { |h| h.contents }.join(", ")
        end

        # Returns the formatted mail message
        def to_s; @headers.to_s + "\n\n" + ( @body || ""); end
    end
end
