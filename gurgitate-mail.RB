#------------------------------------------------------------------------
# Mail filter package
#------------------------------------------------------------------------

require 'etc'

module Gurgitate

    #========================================================================
    # A little class for a single header
    #========================================================================
    class Header
        # The name of the header
        attr_accessor :name
        # The contents of the header
        attr_accessor :contents

        # Creates a Header object with the header's text in
        # <header>
        def initialize(header)
            (@name,@contents)=header.split(/: /,2)
        end

        # Matches a header to a regex
        def matches (regex)
            @contents =~ regex
        end

        # Returns the header, ready to put into an email message
        def to_s
            @name+": "+@contents
        end
    end

    #========================================================================
    # A slightly bigger class for all of a message's headers
    #========================================================================
    class Headers
        # Creates a Headers object with the text of the headers in
        # <headertext>
        def initialize(headertext)
            @headers=Hash.new(nil)
            @headertext=headertext

            (unix_from,normal_headers)=headertext.split(/\n/,2);

            # If you run "fetchmail" with the -m option to feed the
            # mail message straight to gurgitate, skipping the "local
            # MTA" step, then it doesn't have a "From " line.  So I
            # have to deal with that by hand.  First, check to see if
            # there's a "From " line present in the first place.
            if unix_from =~ /^From /  then
                @headertext=normal_headers
                @unix_from=unix_from
            else
                # If there isn't, then deal with it after we've
                # worried about the rest of the headers, 'cos we'll
                # have to make our own.
                unix_from=""
            end

            @headertext.split(/\n/).each do |h|
                header=Header.new(h)
                @headers[header.name]=[] if @headers[header.name]==nil;
                @headers[header.name].push(header)
            end

            # Okay, now worry about the "From foo@bar" line.  If it's
            # not there, then make one up from the Return-Path:
            # header.  If there isn't a "Return-Path:" header (then I
            # suspect we have bigger problems, but still) then use
            # From:
            if unix_from == "" then
                fromregex=/([^ ]+@[^ ]+) \(.*\)|[^<]*[<](.*@.*)[>]|([^ ]+@[^ ]+)/;
                if self["Return-Path"] != nil then
                    fromregex.match(self["Return-Path"][0].contents);
                else
                    fromregex.match(self["From"][0].contents);
                end
                address_candidate=$+

                # If there STILL isn't a match, then it's probably safe to
                # assume that it's local mail, and doesn't have an @ in its
                # address.
                if address_candidate == nil then
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
            else
                # If it is there, then grab the email address in it and
                # use that as our official "from".
                fromregex=/^From ([^ ]+@[^ ]+) /;
                fromregex.match(unix_from);
                @from=$+

                # or maybe it's local
                if @from == nil then
                    unix_from =~ /^From (\S+) /;
                    @from=$+
                end
            end
        end

        # Grab the header with name "name"
        def [](name); return @headers[name]; end

        # Who the message is from
        def from
            return @from
        end

        # Return true if header <name> matches <regex>
        def match(name,regex)
            ret=false
            if(@headers[name]) then
                @headers[name].each do |h|
                    ret |= h.matches(regex)
                end
            end
            return ret
        end

        # Return true if headers <names> match <regex>
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
        def to_s
            return @unix_from+"\n"+@headertext
        end
    end

    #========================================================================
    # A class to deal with a message in its entirety
    #========================================================================
    class Mailmessage
        # The headers of the message
        attr_reader :headers
        # The body of the message
        attr_accessor :body

        def initialize(text)
            (@headertext,@body)=text.split(/^$/,2)
            fromregex=/([^ ]+@[^ ]+) \(.*\)|[^<][<](.*@.*)[>]|([^ ]+@[^ ]+)/;
            @headers=Headers.new(@headertext);
            fromregex.match(@headers["From"][0].contents);
            @from=$+
        end

        # Returns the header <name>
        def header(name)
            @headers[name].each do |h|
                h.contents
            end.join(", ");
        end

        # custom accessors
    
        # Returns the UNIX "from" line
        def from; @headers.from; end

        # Returns the formatted mail message
        def to_s; @headers.to_s+@body; end
    end

    #========================================================================
    # The actual gurgitator; reads a message and then can do other stuff
    # with it, like save to a mailbox or forward somewhere else.
    #========================================================================
    class Gurgitate < Mailmessage
        include Etc
        # The directory you want to put mail folders into
        attr_writer :maildir
        # The path to your log file
        attr_writer :logfile
        # The full path of your "sendmail" program
        attr_writer :sendmail
        # Your home directory
        attr_reader :homedir 
        # Your default mail spool
        attr_reader :spoolfile
        # The directory where user mail spools live
        attr_reader :spooldir
        
        # Constants
        # Spooldir="/var/spool/mail"
        # Spoolfile=Spooldir+"/"+Etc.getlogin()

        # Set config params to defaults, read in mail message from
        # <fh>
        def initialize(input=nil,spooldir="/var/spool/mail")
            @passwd=getpwnam(getlogin)
            @homedir=@passwd.dir;
            @maildir=@passwd.dir+"/Mail"
            @logfile=@passwd.dir+"/.gurgitate.log"
            @sendmail="/usr/lib/sendmail"
            @actiontaken=false
            @spooldir=spooldir
            @spoolfile=@spooldir+"/"+Etc.getlogin()
            if(input.respond_to?(:read))
                super(input.read)
            else
                super(input)
            end
        end

        # Saves a message to a mailbox.
        # If the mailbox is of the form "=mailbox", it puts it into
        # Maildir/mailbox.
        # Otherwise, it puts it into the file you ask for.
        def save(mailbox)
            if mailbox[0,1]=='=' and @maildir != nil
                mailbox["="]=@maildir+"/"
            end

            if mailbox[0,1] != '/'
                log("Cannot save to relative filenames!  Saving to spool file");
                mailbox=spoolfile
            end

            log("Saving to mailbox "+mailbox)
            begin
                File.open(mailbox,"a") do |f|
                    f.flock(File::LOCK_EX)
                    # Do this all at once so that it doesn't write half a message
                    # if it's going to barf
                    # f.print "From "+self.from+" "+Time.new.to_s+"\n"
                    f.print self.to_s+"\n"
                    f.flock(File::LOCK_UN)
                end
            rescue SystemCallError
                self.log "Gack!  Something went wrong: "+$!
                exit 75
            end
        end
        
        # deletes the current message
        def delete
        end

        # Forwards the message to <address>
        def forward(address)
            self.log "Forwarding to "+address
            IO.popen(@sendmail+" "+address,"w") do |f|
                f.print(self.to_s)
            end
        end

        # Writes <message> to the log file.
        def log(message)
            if(@logfile)then
                File.open(@logfile,"a") do |f|
                    f.flock(File::LOCK_EX)
                    f.print(Time.new.to_s+" "+message+"\n")
                    f.flock(File::LOCK_UN)
                end
            end
        end

        # Pipes the message through <program>.  If <program>
        # fails, puts the message into <spoolfile>
        def pipe(program)
            self.log "Piping through "+program
            IO.popen(program,"w") do |f|
                f.print(self.to_s)
            end
            return $?>>8
          rescue SystemCallError
            save(spoolfile())
            return -1
        end

        # Pipes the message through a program, and returns another
        # Gurgitate object containing the output of the filter
        def filter(program)
            self.log "Filtering with "+program
            IO.popen("-","w+") do |filter|
                if filter.nil? then
                    exec(program)
                else
                    if fork
                        filter.close_write
                        return Gurgitate.new(filter)
                    else
                        filter.close_read
                        filter.print(self.to_s)
                        filter.close
                        exit
                    end
                end
            end
          rescue SystemCallError
            save(Spoolfile)
            return nil
        end

        # Processes your .gurgitate-rules.rb.
        def process
            configfilespec=homedir+"/.gurgitate-rules.rb"
            if FileTest.exist?(configfilespec) and 
                FileTest.file?(configfilespec) and 
                FileTest.owned?(configfilespec) and 
                FileTest.readable?(configfilespec)
            then
                configfile=File.new(configfilespec)
                rules=configfile.read
                eval rules 
                save(spoolfile)
            else
                save(spoolfile)
            end
          rescue ScriptError
            log "Couldn't load .gurgitate-rules: "+$!
            save(spoolfile)
        end
    end
end
