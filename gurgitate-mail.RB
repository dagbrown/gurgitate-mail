#------------------------------------------------------------------------
# Mail filter package
#------------------------------------------------------------------------

require 'etc'

#========================================================================
# A little class for a single header
#========================================================================
class Header
    attr_accessor :name
    attr_accessor :contents

    def initialize(header)
        (@name,@contents)=header.split(/: /,2)
    end

    def matches (regex)
        @contents =~ regex
    end

    def to_s
        @name+": "+@contents
    end
end

#========================================================================
# A slightly bigger class for all a message's headers
#========================================================================
class Headers
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

    def [](name); return @headers[name]; end

    def from
        return @from
    end

    def match(name,regex)
        ret=false
        if(@headers[name]) then
            @headers[name].each do |h|
                ret |= h.matches(regex)
            end
        end
        return ret
    end

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

    def to_s
        return @unix_from+"\n"+@headertext
    end
end

#========================================================================
# A class to deal with a message in its entirety
#========================================================================
class Mailmessage
    attr_reader :headers;
    attr_accessor :body;

    def initialize(text)
        (@headertext,@body)=text.split(/^$/,2)
        fromregex=/([^ ]+@[^ ]+) \(.*\)|[^<][<](.*@.*)[>]|([^ ]+@[^ ]+)/;
        @headers=Headers.new(@headertext);
        fromregex.match(@headers["From"][0].contents);
        @from=$+
    end

    def header(name)
        @headers[name].each do |h|
            h.contents
        end.join(", ");
    end

    # custom accessors
    def from; @headers.from; end
    def to_s; @headers.to_s+@body; end
end

#========================================================================
# The actual gurgitator; reads a message and then can do other stuff
# with it, like save to a mailbox or forward somewhere else.
#========================================================================
class Gurgitate < Mailmessage
    include Etc
    attr_writer :maildir, :logfile, :sendmail;
    attr_reader :homedir;
    
    # Constants
    Spooldir="/var/spool/mail"
    Spoolfile=Spooldir+"/"+Etc.getlogin()

    # Set config params to defaults, read in mail message
    def initialize(fh=nil)
        @passwd=getpwnam(getlogin)
        @homedir=@passwd.dir;
        @maildir=@passwd.dir+"/Mail"
        @logfile=@passwd.dir+"/.gurgitate.log"
        @sendmail="/usr/lib/sendmail"
        @actiontaken=false
        if(fh)
            super(fh.read)
        end
    end

    # Read-only stuff
    def spoolfile; Spoolfile; end

    #--------------------------------------------------
    # Save a message to a mailbox
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
    
    def delete
    end

    #--------------------------------------------------
    # Forwards the message to the address you ask for.
    def forward(address)
        self.log "Forwarding to "+address
        IO.popen(@sendmail+" "+address,"w") do |f|
            f.print(self.to_s)
        end
    end

    #--------------------------------------------------
    # Writes a log message to the log file.
    def log(message)
        if(@logfile)then
            File.open(@logfile,"a") do |f|
                f.flock(File::LOCK_EX)
                f.print(Time.new.to_s+" "+message+"\n")
                f.flock(File::LOCK_UN)
            end
        end
    end

    #--------------------------------------------------
    # Pipes the message through a program
    def pipe(program)
        self.log "Piping through "+program
        IO.popen(program,"w") do |f|
            f.print(self.to_s)
        end
        return $?>>8
      rescue SystemCallError
        save(Spoolfile)
        return -1
    end

    #--------------------------------------------------
    # Pipes the message through a program, returns
    # another Gurgitate object containing the output
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

    #--------------------------------------------------
    # Processes the mail filter
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
