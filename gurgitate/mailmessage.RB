# Contains the class Gurgitate::Mailmessage, used to handle the parsing
# of existing messages and the creation of new messages.

require 'gurgitate/headers'
require 'gurgitate/message'

module Gurgitate

    # A complete mail message.  This is the base class for
    # gurgitate-mail itself: if you want to use gurgitate-mail to create
    # new messages, this is what you want to use.
    class Mailmessage < Message

        Fromregex=/([^ ]+@[^ ]+) \(.*\)|[^<][<](.*@.*)[>]|([^ ]+@[^ ]+)/;

        # The envelope sender and recipient, if anyone thought to
        # mention them to us.
        attr_accessor :sender
        attr_accessor :recipient

        # Creates a new mail message from the options hash, and the body of the
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

                %w/sender recipient body/.each do |key|
                    if options.has_key? key.to_sym
                        instance_variable_set("@#{key}", options[key.to_sym])
                        options.delete key.to_sym
                    end
                end

                @headers = MailHeaders.new(options)
            end

            message
        end

        def initialize(text=nil, recipient=nil, sender=nil)

            @recipient = recipient
            @sender = sender

            if text
                (@headertext,@body)=text.split(/\n\n/,2)
                @headers=MailHeaders.new(@headertext);
                Fromregex.match(@headers["From"][0].contents);
                @from=$+
            else
                super(text)
            end
        end

        # custom accessors
    
        # Returns the message's sender
        def from; @sender || @headers.from; end

        # Returns all the candidates for a recipient
        def to
            if @recipient
                then @recipient
            elsif @headers["To"]
                then @headers["To"][0].contents
            elsif @headers["Cc"]
                then @headers["Cc"][0].contents
            elsif @headers["X-Original-To"]
                then @headers["X-Original-To"][0].contents
            else
                ""
            end
        end

        # Returns the mail message formatted for mbox
        def to_mbox; @headers.to_mbox + "\n\n" + @body; end
    end
end
