#!/opt/bin/ruby
#------------------------------------------------------------------------
# Mail filter package
#------------------------------------------------------------------------

require 'etc'

require 'gurgitate/mailmessage'
require 'gurgitate/deliver'

module Gurgitate
    #========================================================================
    # The actual gurgitator; reads a message and then it can do
    # other stuff with it, like save to a mailbox or forward
    # it somewhere else.
    class Gurgitate < Mailmessage
        include Deliver

        # Instead of the usual attributes, I went with a
        # reader-is-writer type thing (as seen quite often in Perl and
        # C++ code) so that in your .gurgitate-rules, you can say
        # 
        # maildir "#{homedir}/Mail"
        # sendmail "/usr/sbin/sendmail"
        # spoolfile "Maildir"
        # spooldir homedir
        #
        # This is because of an oddity in Ruby where, even if an
        # accessor exists in the current object, if you say:
        #    name = value
        # it'll always create a local variable.  Not quite what you
        # want when you're trying to set a config parameter.  You have
        # to say "self.name = value", which (I think) is ugly.
        #
        # In the interests of promoting harmony, of course, the previous
        # syntax will continue to work.
        def self.attr_configparam(*syms)
            syms.each do |sym|
                class_eval %/
                    def #{sym} (*vals)
                        if vals.length == 1
                            @#{sym} = vals[0]
                        elsif vals.length == 0
                            @#{sym}
                        else
                            raise ArgumentError, 
                                "wrong number of arguments " +
                                "(\#{vals.length} for 0 or 1)"
                        end
                    end

                    # Don't break it for the nice people who use 
                    # old-style accessors though.  Breaking people's
                    # .gurgitate-rules is a bad idea.
                    attr_writer :#{sym}
                /
            end
        end

        # The directory you want to put mail folders into
        attr_configparam :maildir

        # The path to your log file
        attr_configparam :logfile

        # The full path of your "sendmail" program
        attr_configparam :sendmail

        # Your home directory
        attr_configparam :homedir 

        # Your default mail spool
        attr_configparam :spoolfile

        # The directory where user mail spools live
        attr_configparam :spooldir

        # What kind of mailboxes you prefer
        # attr_configparam :folderstyle

        # What kind of mailboxes you prefer
        def folderstyle(*style)
            if style.length == 0 then
                @folderstyle
            elsif style.length == 1 then
                if style[0] == Maildir then
                    spooldir homedir
                    spoolfile File.join(spooldir,"Maildir")
                    maildir spoolfile
                else
                    spooldir "/var/spool/mail"
                    spoolfile File.join(spooldir, @passwd.name)
                end
                @folderstyle = style[0]
            else
                raise ArgumentError, "wrong number of arguments "+
                                     "(#{style.length} for 0 or 1)"
            end
            @folderstyle
        end

        # Set config params to defaults, read in mail message from
        # +input+
        # input::
        #   Either the text of the email message in RFC-822 format,
        #   or a filehandle where the email message can be read from
        # recipient::
        #   The contents of the envelope recipient parameter
        # sender::
        #   The envelope sender parameter
        # spooldir::
        #   The location of the mail spools directory.
        def initialize(input=nil,
                       recipient=nil,
                       sender=nil, 
                       spooldir="/var/spool/mail",
                       &block)
            @passwd      = Etc.getpwuid
            @homedir     = @passwd.dir;
            @maildir     = File.join(@passwd.dir,"Mail")
            @logfile     = File.join(@passwd.dir,".gurgitate.log")
            @sendmail    = "/usr/lib/sendmail"
            @spooldir    = spooldir
            @spoolfile   = File.join(@spooldir,@passwd.name )
            @folderstyle = MBox
            @rules       = []

            input_text = ""
            input.each do |l| input_text << l end
            super(input_text, recipient, sender)
            instance_eval(&block) if block_given?
        end

        def add_rules(filename, options = {})
            if not Hash === options
                raise ArgumentError.new("Expected hash of options")
            end
            if filename == :default
                filename=homedir+"/.gurgitate-rules"
            end
            if not FileTest.exist?(filename)
                filename = filename + '.rb'
            end
            if not FileTest.exist?(filename)
              if options.has_key?(:user)
                log("#{filename} does not exist.")
              end
              return false
            end
            if FileTest.file?(filename) and
                ( ( not options.has_key? :system and
                    FileTest.owned?(filename) ) or
                  ( options.has_key? :system and
                    options[:system] == true and
                    File.stat(filename).uid == 0 ) ) and
                FileTest.readable?(filename)
                @rules << filename
            else
                log("#{filename} has bad permissions or ownership, not using rules")
                return false
            end
        end

        # Deletes the current message.
        def delete
            # Well, nothing here, really.
        end

        # This is a neat one.  You can get any header as a method.
        # Say, if you want the header "X-Face", then you call
        # x_face and that gets it for you.  It raises NameError if
        # that header isn't found.
        # meth::
        #   The method that the caller tried to call which isn't
        #   handled any other way.
        def method_missing(meth)
            headername=meth.to_s.split(/_/).map {|x| x.capitalize}.join("-")
            if defined?(headers[headername]) then
                return headers[headername]
            else
                raise NameError,"undefined local variable or method, or header not found `#{meth}' for #{self}:#{self.class}"
            end
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
        def filter(program,&block)
            self.log "Filtering with "+program
            IO.popen("-","w+") do |filter|
                if filter.nil? then
                    exec(program)
                else
                    if fork
                        filter.close_write
                        g=Gurgitate.new(filter)
                        g.instance_eval(&block) if block_given?
                        return g
                    else
                        filter.close_read
                        filter.print(self.to_s)
                        filter.close
                        exit!
                    end
                end
            end
          rescue SystemCallError
            save(Spoolfile)
            return nil
        end

        # Processes your .gurgitate-rules.rb.
        def process(&block)
            if @rules.size > 0 or block
                @rules.each do |configfilespec|
                    begin
                        eval File.new(configfilespec).read, nil,
                            configfilespec
                    rescue ScriptError
                        log "Couldn't load #{configfilespec}: "+$!
                        save(spoolfile)
                    rescue Exception
                        log "Error while executing #{configfilespec}: #{$!}"
                        $@.each { |tr| log "Backtrace: #{tr}" }
                        folderstyle = MBox
                        save(spoolfile)
                    end
                end
                if block
                    instance_eval(&block)
                end
                log "Mail not covered by rules, saving to default spool"
                save(spoolfile)
            else
                save(spoolfile)
            end
        end
    end
end
