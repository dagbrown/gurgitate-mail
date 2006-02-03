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
        # What kind of mailboxes you prefer
        attr_writer :folderstyle
        
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
            @passwd      = Etc.getpwuid
            @homedir     = @passwd.dir;
            @maildir     = File.join(@passwd.dir,"Mail")
            @logfile     = File.join(@passwd.dir,".gurgitate.log")
            @sendmail    = "/usr/lib/sendmail"
            @spooldir    = spooldir
            @spoolfile   = File.join(@spooldir,@passwd.name )
            @folderstyle = MBox

            input_text = ""
            input.each do |l| input_text << l end
            super(input_text)
            instance_eval(&block) if block_given?
        end

        # Deletes the current message.
        def delete
            # Well, nothing here, really.
            true
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
                        exit
                    end
                end
            end
          rescue SystemCallError
            save(Spoolfile)
            return nil
        end

        # Processes your .gurgitate-rules.rb.
        def process(configfilespec=homedir+"/.gurgitate-rules",*options)
            if options.length == 1 and Hash === options[0] then
                options=options[0]
            elsif options.length != 0 then
                raise ArgumentError.new("Expected hash of options")
            end
            # Have a quick look around for ~/.gurgitate-rules, and
            # if it's not there, try for .gurgitate-rules.rb instead
            if not FileTest.exist?(configfilespec) then
                configfilespec = "#{configfilespec}.rb"
            end
            if FileTest.exist?(configfilespec) and 
                FileTest.file?(configfilespec) and 
                ( ( not options.has_key? :system and 
                    FileTest.owned?(configfilespec) ) or
                  ( options.has_key? :system and
                    options[:system] == true and
                    File.stat(configfile).uid == 0 ) ) and
                FileTest.readable?(configfilespec)
            then
                eval File.new(configfilespec).read
            elsif options.has_key? :chain and options[:chain] = true
                return self
            else
                save(spoolfile)
            end
          rescue ScriptError
            log "Couldn't load .gurgitate-rules: "+$!
            save(spoolfile)
          rescue Exception
              log "Error while executing .gurgitate-rules.rb: #{$!}"
              $@.each { |tr| log "Backtrace: #{tr}" }
              folderstyle = MBox
              save(spoolfile)
          end
      end
  end
