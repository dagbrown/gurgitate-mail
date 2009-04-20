#!/opt/bin/ruby -w

require "gurgitate/headers"

module Gurgitate
    class IllegalHeader < RuntimeError ; end

# ========================================================================

    # A slightly bigger class for all of a message's headers
    class MailHeaders < Headers

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
            (unix_from,normal_headers)  = headertext.split(/\n/,2)

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
            #
            # And then after all that fuss, if we're delivering to a
            # Maildir, I have to get rid of it.  And sometimes the MTA
            # gives me a mbox-style From line and sometimes it doesn't.
            # It's annoying, but I have no choice but to Just Deal With
            # It.
            if @unix_from then
                # If it is there, then grab the email address in it and
                # use that as our official "from".
                fromregex=/^From ([^ ]+@[^ ]+) /
                fromregex.match(@unix_from)
                @from=$+

                # or maybe it's local
                if @from == nil then
                    @unix_from =~ /^From (\S+) /
                    @from=$+
                end
            else
                fromregex=/([^ ]+@[^ ]+) \(.*\)|[^<]*[<](.*@.*)[>]|([^ ]+@[^ ]+)/
                if self["Return-Path"] != nil then
                    fromregex.match(self["Return-Path"][0].contents)
                else
                    if self["From"] != nil then
                        fromregex.match(self["From"][0].contents)
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

                @unix_from="From "+self.from+" "+Time.new.to_s
            end
        end

        public

        # Creates a MailHeaders object.
        # headertext::
        #   The text of the message headers.
        def initialize(headertext=nil, sender=nil, recipient=nil)
            @from    = sender
            @to      = recipient
            @headers = Hash.new(nil)

            if Hash === headertext
                @headers_changed = true
                headertext.each_key do |key|

                    headername = key.to_s.gsub("_","-")

                    header=Header.new(headername, headertext[key])
                    @headers[header.name] ||= HeaderBag.new
                    @headers[header.name].push(header)
                end
            else
                if headertext
                    @unix_from, @headertext = figure_out_from_line headertext
                    parse_headers if @headertext

                    if sender # then don't believe the mbox separator
                        @from = sender
                        @unix_from="From "+self.from+" "+Time.new.to_s
                    else
                        guess_sender
                    end
                end
            end
        end

        # Who the message is to (the envelope to)
        #
        # Yet another bucket of rants.  Unix mail sucks.
        def to
            return @to || @headers["X-Original-To"] || nil
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
            @unix_from="From "+self.from+" "+Time.new.to_s
        end

        # Returns the headers properly formatted for an mbox-format
        # email message.
        def to_mbox
            return @unix_from+"\n"+to_s
        end
    end
end
