#!/opt/bin/ruby -w

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
                    (name,contents)=header[0].split(/:\s+/,2)
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
            @contents =~ regex
        end

        alias :=~ :matches

        # Returns the header, ready to put into an email message
        def to_s
            @name+": "+@contents
        end
    end

# ========================================================================

    class HeaderBag < Array
        def =~(regex)
            inject(false) do |y,x|
                y or ( ( x =~ regex ) != nil )
            end
        end

        def sub!(regex, replacement)
            each do |header|
                header.contents = header.contents.sub regex, replacement
            end
            p self
        end
        
        def sub(regex, replacement)
            ::Gurgitate::HeaderBag.new(
                self.map do |header|
                    ::Gurgitate::Header.new(
                        "#{header.name}: " + header.contents.sub(regex, 
                                                                 replacement)
                    )
                end
            )
        end

    end

    # A slightly bigger class for all of a message's headers
    class Headers

        private

        # Figures out whether the first line of a mail message is an
        # mbox-style "From " line (say, if you get this from sendmail),
        # or whether it's just a normal header.
        # -- 
        # If you run "fetchmail" with the -m option to feed the
        # mail message straight to gurgitate, skipping the "local
        # MTA" step, then it doesn't have a "From " line.  So I
        # have to deal with that by hand.  First, check to see if
        # there's a "From " line present in the first place.
        def figure_out_from_line(headertext)
            (unix_from,normal_headers)  = headertext.split(/\n/,2);

            if unix_from =~ /^From /  then
                headertext=normal_headers
                unix_from=unix_from
            else
                # If there isn't, then deal with it after we've
                # worried about the rest of the headers, 'cos we'll
                # have to make our own.
                unix_from=nil
            end
            return unix_from, headertext
        end

        def parse_headers
            @headertext.each do |h|
                h.chomp!
                if(h=~/^\s+/) then
                    @lastheader << h
                else
                    header=Header.new(h)
                    @headers[header.name] ||= HeaderBag.new;
                    @headers[header.name].push(header)
                    @lastheader=header
                end
            end

            @headers_changed=false
        end

        # Get the envelope From information.  This comes with a
        # whole category of rants: this information is absurdly hard
        # to get your hands on.  The best you can manage is a sort
        # of educated guess.  Thus, this horrible glob of hackiness.
        # I don't recommend looking too closely at this code if you
        # can avoid it, and further I recommend making sure to
        # configure your MTA so that it sends proper sender and
        # recipient information to gurgitate so that this code never
        # has to be run at all.
        def guess_sender
            # Start by worrying about the "From foo@bar" line.  If it's
            # not there, then make one up from the Return-Path: header.
            # If there isn't a "Return-Path:" header (then I suspect we
            # have bigger problems, but still) then use From: as a wild
            # guess.  If I hope that this entire lot of code doesn't get
            # used, then I _particularly_ hope that things never get so
            # bad that poor gurgitate has to use the From: header as a
            # source of authoritative information on anything.
            if @unix_from then
                # If it is there, then grab the email address in it and
                # use that as our official "from".
                fromregex=/^From ([^ ]+@[^ ]+) /;
                fromregex.match(@unix_from);
                @from=$+

                # or maybe it's local
                if @from == nil then
                    @unix_from =~ /^From (\S+) /;
                    @from=$+
                end
            else
                fromregex=/([^ ]+@[^ ]+) \(.*\)|[^<]*[<](.*@.*)[>]|([^ ]+@[^ ]+)/;
                if self["Return-Path"] != nil then
                    fromregex.match(self["Return-Path"][0].contents);
                else
                    if self["From"] != nil then
                        fromregex.match(self["From"][0].contents);
                    end
                end
                address_candidate=$+

                # If there STILL isn't a match, then it's probably safe to
                # assume that it's local mail, and doesn't have an @ in its
                # address.
                unless address_candidate
                    if self["Return-Path"] != nil then
                        self["Return-Path"][0].contents =~ /(\S+)/
                        address_candidate=$+
                    else
                        self["From"][0].contents =~ /(\S+)/
                        address_candidate=$+
                    end
                end

                @from=address_candidate

                @unix_from="From "+self.from+" "+Time.new.to_s;
            end
        end

        public

        # Creates a Headers object.
        # headertext::
        #   The text of the message headers.
        def initialize(headertext=nil,sender=nil, recipient=nil)
            @headers = Hash.new(nil)

            if Hash === headertext
                @headers_changed = true
                headertext.each_key do |key|

                    headername = key.to_s.gsub("_","-")

                    header=Header.new(headername, headertext[key])
                    @headers[header.name] ||= HeaderBag.new;
                    @headers[header.name].push(header)
                end
            else
                if headertext
                    @unix_from, @headertext = figure_out_from_line headertext
                    parse_headers if @headertext

                    if sender
                        @from = sender
                        @unix_from="From "+self.from+" "+Time.new.to_s;
                    else
                        guess_sender
                    end
                end
            end
        end

        # Grab the headers with names +names+
        # names:: The names of the header.
        def [](*names)
            if names.inject(false) do |accum,name| 
                accum or @headers.has_key? name
            end then
                return HeaderBag.new(names.collect { |name| 
                        @headers[name] 
                    }.flatten.delete_if { |e| e == nil } )
            else
                return nil
            end
        end

        # Set the header named +name+ to +value+
        # name:: The name of the header.
        # value:: The new value of the header.
        def []=(name,value)
            @headers_changed = true
            @headers[name]=HeaderBag.new([Header.new(name,value)])
        end

        # Who the message is to (the envelope to)
        #
        # Yet another bucket of rants.  Unix mail sucks.
        def to
            return @headers["X-Original-To"] || nil
        end

        # Who the message is from (the envelope from)
        def from
            return @from || ""
        end

        # Change the envelope from line to whatever you want.  This might
        # not be particularly neighborly, but oh well.
        # newfrom:: An email address
        def from=(newfrom) 
            @from=newfrom
            @unix_from="From "+self.from+" "+Time.new.to_s;
        end

        # Match header +name+ against +regex+
        # name:: 
        #   A string containing the name of the header to match (for example,
        #   "From")
        # regex:: The regex to match it against (for example, /@aol.com/)
        def match(name,regex)
            ret=false
            if(@headers[name]) then
                @headers[name].each do |h|
                    ret |= h.matches(regex)
                end
            end
            return ret
        end

        # Return true if headers +names+ match +regex+
        # names:: An array of header names (for example, %w{From Reply-To})
        # regex:: The regex to match the headers against.
        def matches(names,regex)
            ret=false
            if names.class == "String" then
                names=[names];
            end
            names.each do |n|
                ret |= match(n,regex)
            end
            return ret
        end

        # Returns the headers properly formatted for an email
        # message.
        def to_mbox
            return @unix_from+"\n"+to_s
        end

        # Returns the headers formatted for an email message (without
        # the "From " line
        def to_s
            if @headers_changed then
                return @headers.map do |n,h|
                    h.map do |h| h.to_s end.join("\n")
                end.join("\n")
            else
                return @headertext
            end
        end
    end
end
