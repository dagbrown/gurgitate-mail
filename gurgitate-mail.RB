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
            @passwd    = Etc.getpwuid
            @homedir   = @passwd.dir;
            @maildir   = File.join(@passwd.dir,"Mail")
            @logfile   = File.join(@passwd.dir,".gurgitate.log")
            @sendmail  = "/usr/lib/sendmail"
            @spooldir  = spooldir
            @spoolfile = File.join(@spooldir,@passwd.name )

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
