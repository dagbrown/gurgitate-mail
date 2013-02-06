#!/opt/bin/ruby -w
# -*- encoding : utf-8 -*-

module Gurgitate
    class IllegalHeader < RuntimeError ; end

    # A little class for a single header
    class Header
        # The name of the header
        attr_accessor :name
        # The contents of the header
        attr_accessor :contents

        alias_method :value, :contents

        # A recent rash of viruses has forced me to canonicalize
        # the capitalization of headers.  Sigh.
        def capitalize_words(s)
            return s.split(/-/).map { |w| w.capitalize }.join("-")
          rescue
            return s
        end

        private :capitalize_words

        # Creates a Header object.
        # header::
        #   The text of the email-message header
        def initialize(*header)
            name,contents=nil,nil
            if header.length == 1 then
                # RFC822 says that a header consists of some (printable,
                # non-whitespace) crap, followed by a colon, followed by
                # some more (printable, but can include whitespaces)
                # crap.
                if(header[0] =~ /^[\x21-\x39\x3b-\x7e]+:/) then
                    (name,contents)=header[0].split(/:\s*/,2)
                    if(name =~ /:$/ and contents == nil) then
                        # It looks like someone is using Becky!
                        name=header[0].gsub(/:$/,"")
                        contents = ""
                    end

                    raise IllegalHeader, "Empty name" \
                        if (name == "" or name == nil)
                    contents="" if contents == nil

                    @@lastname=name
                else
                    raise IllegalHeader, "Bad header syntax: no colon in #{header}"
                end
            elsif header.length == 2 then
                name,contents = *header
            end

            @name=capitalize_words(name)
            @contents=contents
        end

        # Extended header
        def << (text)
            @contents += "\n" + text
        end

        # Matches a header's contents.
        # regex::
        #   The regular expression to match against the header's contents
        def matches (regex)
            if String === regex
                regex = Regexp.new(Regexp.escape(regex))
            end
            @contents =~ regex
        end

        alias :=~ :matches

        # Returns the header, ready to put into an email message
        def to_s
            @name+": "+@contents
        end
    end
end
