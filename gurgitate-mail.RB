#!/opt/bin/ruby
#------------------------------------------------------------------------
# Mail filter package
#------------------------------------------------------------------------

require 'etc'

module Gurgitate

#========================================================================


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
        end

        private :capitalize_words

        # Creates a Header object.
        # header::
        #   The text of the email-message header
        def initialize(header)
            if(header =~ /: /) then
                (name,contents)=header.split(/: /,2)

                raise IllegalHeader, "Empty name" \
                    if (name == "" or name == nil)
                raise IllegalHeader, "Bad header syntax: #{name}" \
                    if contents == nil
                raise IllegalHeader, "Empty header contents" \
                    if contents == ""

                @@lastname=name
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

        # Returns the header, ready to put into an email message
        def to_s
            @name+": "+@contents
        end
    end

#========================================================================

    # A slightly bigger class for all of a message's headers
    class Headers

        # Creates a Headers object.
        # headertext::
        #   The text of the message headers.
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
                if(h=~/^\s+/) then
                    @lastheader << h
                else
                    header=Header.new(h)
                    @headers[header.name]=[] if @headers[header.name]==nil;
                    @headers[header.name].push(header)
                    @lastheader=header
                end
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

        # Grab the header with name +name+
        # name:: The name of the header.
        def [](name); return @headers[name]; end

        # Who the message is from
        def from
            return @from
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
        def to_s
            return @unix_from+"\n"+@headertext
        end
    end

    #========================================================================

    # A complete mail message.

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

        # Returns the header +name+
        def header(name)
            @headers[name].each { |h| h.contents }.join(", ")
        end

        # custom accessors
    
        # Returns the UNIX "from" line
        def from; @headers.from; end

        # Returns the formatted mail message
        def to_s; @headers.to_s+@body; end
    end

    #========================================================================

    # The actual gurgitator; reads a message and then it can do
    # other stuff with it, like save to a mailbox or forward
    # it somewhere else.
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
        # +input+
        # input::
        #   Either the text of the email message in RFC-822 format,
        #   or a filehandle where the email message can be read from
        # spooldir::
        #   The location of the mail spools directory.
        def initialize(input=nil,spooldir="/var/spool/mail",&block)
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
            
            instance_eval(&block) if block_given?
        end

        # Saves a message to +mailbox+.
        # mailbox::
        #   A string containing the path of the mailbox to save
        #   the message to.  If it is of the form "=mailbox", it
        #   saves the message to +Maildir+/+mailbox+.  Otherwise,
        #   it simply saves the message to the file +mailbox+.
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
                    # Do this all at once so that it doesn't write half a
                    # message if it's going to barf
                    # f.print "From "+self.from+" "+Time.new.to_s+"\n"
                    f.print self.to_s+"\n"
                    f.flock(File::LOCK_UN)
                end
            rescue SystemCallError
                self.log "Gack!  Something went wrong: "+$!
                exit 75
            end
        end
        
        # Deletes the current message.
        def delete
            # Well, nothing here, really.
        end

        # Forwards the message to +address+.
        # address::
        #   A valid email address to forward the message to.
        def forward(address)
            self.log "Forwarding to "+address
            IO.popen(@sendmail+" "+address,"w") do |f|
                f.print(self.to_s)
            end
        end

        # Writes +message+ to the log file.
        def log(message)
            if(@logfile)then
                File.open(@logfile,"a") do |f|
                    f.flock(File::LOCK_EX)
                    f.print(Time.new.to_s+" "+message+"\n")
                    f.flock(File::LOCK_UN)
                end
            end
        end

        # Pipes the message through +program+.  If +program+
        # fails, puts the message into +spoolfile+
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

        # Pipes the message through +program+, and returns another
        # +Gurgitate+ object containing the output of the filter
        def filter(program)
            self.log "Filtering with "+program
            IO.popen("-","w+") do |filter|
                if filter.nil? then
                    exec(program)
                else
                    if fork
                        filter.close_write
                        return Gurgitate::Gurgitate.new(filter)
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
        def process(configfilespec=homedir+"/.gurgitate-rules.rb")
            if FileTest.exist?(configfilespec) and 
                FileTest.file?(configfilespec) and 
                FileTest.owned?(configfilespec) and 
                FileTest.readable?(configfilespec)
            then
                eval File.new(configfilespec).read
            else
                save(spoolfile)
            end
          rescue ScriptError
            log "Couldn't load .gurgitate-rules: "+$!
            save(spoolfile)
        end
    end
end
