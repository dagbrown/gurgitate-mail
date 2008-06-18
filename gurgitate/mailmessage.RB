# Contains the class Gurgitate::Mailmessage, used to handle the parsing
# of existing messages and the creation of new messages.

require 'gurgitate/headers'

module Gurgitate

    # A complete mail message.  This is the base class for
    # gurgitate-mail itself: if you want to use gurgitate-mail to create
    # new messages, this is what you want to use.
    class Mailmessage

        Fromregex=/([^ ]+@[^ ]+) \(.*\)|[^<][<](.*@.*)[>]|([^ ]+@[^ ]+)/;

        # The headers of the message
        attr_reader :headers

        # The body of the message
        attr_accessor :body

        # The envelope sender 
        attr_accessor :sender

        # The envelope recipient
        attr_accessor :recipient

        # Creates a new mail message with headers built from the options hash,
        # and the body of the message in a string.
        # 
        # For example:
        #
        #   msg = Gurgitate::Mailmessage.create :from => "myaddress@example.com",
        #                                       :to => "destination@example.com",
        #                                       :subject => "Test",
        #                                       :body => << EOT
        #   YOU MAY ALREADY BE A WINNER!  Please visit this web site
        #   at http://evilspammers.example.com/ and have your credit
        #   card number, validation number and expiry date handy!
        #   EOT
        #
        # For args, you can give it either a hash as demonstrated above,
        # the body of the message followed by the contents of the
        # headers as a hash.
        #
        # In addition to the usual complement of headers that you can
        # give to an email message, you can also use the three "special"
        # headers <code>:sender</code>, <code>:recipient+</code>, and
        # <code>:body</code> as such:
        #
        # <code>:sender</code> :: The envelope sender of the mail message
        # <code>:recipient</code> :: The envelope recipient of the mail message
        # <code>:body</code> :: The body of the mail message.  When a body is
        # specified as a text argument and in the options hash, the body
        # given in the options hash is used.
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

                @headers = Headers.new(options)
            end

            message
        end

        # Returns a new mail message created from a text stream.
        #
        # The text of the message, recipient and sender can all be omitted--if
        # they are, then a new empty message will be created.
        #
        # text::  A mail message in RFC-822 format.
        # recipient::  The envelope recipient of the mail message.
        # sender:: The envelope sender of the mail message.
        def initialize(text=nil, recipient=nil, sender=nil)

            @recipient = recipient
            @sender = sender

            if text
                (@headertext,@body)=text.split(/\n\n/,2)
                @headers=Headers.new(@headertext);
                Fromregex.match(@headers["From"][0].contents);
                @from=$+
            else
                @headers = Headers.new
                @body = ""
            end
        end

        # Returns the header +name+
        def header(name)
            @headers[name].each { |h| h.contents }.join(", ")
        end

        # custom accessors
    
        # Returns the message's envelope sender, if available.  If not
        # available, returns the messages's From header as an approximation.
        # 
        # If you really need the envelope sender and not a best guess, use 
        # +sender+ instead.
        def from; sender || @headers.from; end

        # Returns the message's envelope recipient, if available.  If not
        # available, returns either the first "To" header, or failing that, the
        # first "Cc" header.
        #
        # If you really need the envelope recipient and not a best guess,
        # user +recipient+ instead.
        def to; recipient || @headers["To", "Cc"][0].contents; end

        # Returns the mail message formatted as an RFC-822 stream, ready for
        # delivering.
        def to_s; @headers.to_s + "\n\n" + ( @body || ""); end

        # Returns the mail message formatted for dropping directly into an mbox
        # format mailbox (that is to say, with 
        # 
        #    From {envelope_sender} {date}
        #
        # as the first line of the message.
        def to_mbox; @headers.to_mbox + "\n\n" + @body; end
    end
end
