#!/opt/bin/ruby -w

#------------------------------------------------------------------------
# Handles a complete mail message
#------------------------------------------------------------------------

require 'gurgitate/headers'

module Gurgitate

    # A complete mail message.
    class Mailmessage

        Fromregex=/([^ ]+@[^ ]+) \(.*\)|[^<][<](.*@.*)[>]|([^ ]+@[^ ]+)/;

        # The headers of the message
        attr_reader :headers
        # The body of the message
        attr_accessor :body

        # The envelope sender and recipient, if anyone thought to
        # mention them to us.
        attr_accessor :sender
        attr_accessor :recipient

        # Creates a new mail message with headers built from the options hash,
        # and the body of the message in a string.
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
    
        # Returns the message's sender
        def from; @sender || @headers.from; end

        # Returns all the candidates for a recipient
        def to; @recipient || @headers["To", "Cc"][0].contents; end

        # Returns the formatted mail message
        def to_s; @headers.to_s + "\n\n" + ( @body || ""); end

        # Returns the mail message formatted for mbox
        def to_mbox; @headers.to_mbox + "\n\n" + @body; end
    end
end
