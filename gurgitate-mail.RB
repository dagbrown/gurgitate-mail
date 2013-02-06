#!/opt/bin/ruby
# -*- encoding : utf-8 -*-
#------------------------------------------------------------------------
# Mail filter package
#------------------------------------------------------------------------

require 'etc'

require 'gurgitate/mailmessage'
require 'gurgitate/deliver'

module Gurgitate
    # This is the actual gurgitator; it reads a message and then it can
    # do other stuff with it, like saving it to a mailbox or forwarding
    # it somewhere else.
    #
    # To set configuration parameters for gurgitate-mail, use a keyword-
    # based system.  It's almost like an attribute, only if you give the
    # accessor a parameter, it will set the configuration parameter to
    # the parameter's value.  For instance:
    #
    #  maildir "#{homedir}/Mail"
    #  sendmail "/usr/sbin/sendmail"
    #  spoolfile "Maildir"
    #  spooldir homedir
    #
    # (This is because of an oddity in Ruby where, even if an
    # accessor exists in the current object, if you say:
    #    name = value
    # it'll always create a local variable.  Not quite what you
    # want when you're trying to set a config parameter.  You have
    # to say <code>self.name = value</code>, which [I think] is ugly.
    #
    # In the interests of promoting harmony, of course,
    # <code>self.name = value</code> still works.)
    #
    # The attributes you can define are:
    #
    # homedir ::  Your home directory.  This defaults to what your
    #             actual home directory is.
    #
    # maildir :: The directory you store your mail in.  This defaults
    #            to the "Mail" directory in your home dir.
    #
    # logfile :: The path to your gurgitate-mail log file.  If you
    #            set this to +nil+, gurgitate-mail won't log anything.
    #            The default value is ".gurgitate.log" in your home
    #            directory.
    #
    # The following parameters are more likely to be interesting to the
    # system administrator than the everyday user.
    #
    # sendmail :: The full path of your "sendmail" program, or at least
    #             a program that provides functionality equivalent to
    #             sendmail.
    #
    # spoolfile :: The default location to store mail messages, for the
    #              messages that have been unaffected by your gurgitate
    #              rules.  If an exception is raised by your rules, the
    #              message will be delivered to the spoolfile.
    #
    # spooldir :: The location where users' system mail boxes live.
    #
    # folderstyle :: The style of mailbox to create (and to expect,
    #                although gurgitate-mail automatically detects the
    #                type of existing mailboxes).  See the separate
    #                documentation for folderstyle for more details.
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
                class_eval %{
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
                }
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

        # What kind of mailboxes you prefer.  Treat this like a
        # configuration parameter.  If no argument is given, then
        # return the current default type.
        #
        # Depending on what you set this to, some other configuration
        # parameters change.  You can set this to the following things:
        #
        # <code>Maildir</code> :: Create Maildir mailboxes.
        #
        #                         This sets +spooldir+ to your home
        #                         directory, +spoolfile+ to
        #                         $HOME/Maildir and creates
        #                         mail folders underneath that.
        #
        # <code>MH</code> :: Create MH mail boxes.
        #
        #                    This reads your <code>.mh_profile</code>
        #                    file to find out where you've told MH to
        #                    find its mail folders, and uses that value.
        #                    If it can't find that in your .mh_profile,
        #                    it will assume you want mailboxes in
        #                    $HOME/Mail.  It sets +spoolfile+ to
        #                    "inbox" in your mail directory.
        #
        # <code>Mbox</code> :: Create +mbox+ mailboxes.
        #
        #                      This sets +spooldir+ to
        #                      <code>/var/spool/mail</code> and
        #                      +spoolfile+ to a file with your username
        #                      in <code>/var/spool/mail</code>.
        def folderstyle(*style)
            if style.length == 0 then
                @folderstyle
            elsif style.length == 1 then
                if style[0] == Maildir then
                    spooldir homedir
                    spoolfile File.join(spooldir,"Maildir")
                    maildir spoolfile
                elsif style[0] == MH then
                    mh_profile_path = File.join(ENV["HOME"],".mh_profile")
                    if File.exists?(mh_profile_path) then
                        mh_profile = YAML.load(File.read(mh_profile_path))
                        maildir mh_profile["Path"]
                    else
                        maildir File.join(ENV["HOME"],"Mail")
                    end
                    spoolfile File.join(maildir,"inbox")
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
            input.each_line do |l| input_text << l end
            super(input_text, recipient, sender)
            instance_eval(&block) if block_given?
        end

        def add_rules(filename, options = {}) #:nodoc:
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

        # Deletes (discards) the current message.
        def delete
            # Well, nothing here, really.
        end

        # This is kind of neat.  You can get a header by calling its
        # name as a method.  For example, if you want the header
        # "X-Face", then you call x_face and that gets it for you.  It
        # raises NameError if that header isn't found.
        #
        # meth::
        #   The method that the caller tried to call which isn't
        #   handled any other way.
        def method_missing(meth)
            headername=meth.to_s.split(/_/).map {|x| x.capitalize}.join("-")
            if headers[headername] then
                return headers[headername]
            else
                raise NameError,"undefined local variable or method, or header not found `#{meth}' for #{self}:#{self.class}"
            end
        end

        # Forwards the message to +address+.
        #
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
            if @logfile then
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
        end

        # Pipes the message through +program+, and returns another
        # +Gurgitate+ object containing the output of the filter
        #
        # Use it like this:
        #
        #  filter "bogofilter -p" do
        #    if x_bogosity =~ /Spam/ then
        #      log "Found spam"
        #      delete
        #      return
        #    end
        #  end
        #
        def filter(program,&block)
            self.log "Filtering with "+program
            IO.popen("-","w+") do |filter|
                unless filter then
                    begin
                        exec(program)
                    rescue
                        exit! # should not get here anyway
                    end
                else
                    if fork
                        filter.close_write
                        g=Gurgitate.new(filter)
                        g.instance_eval(&block) if block_given?
                        return g
                    else
                        begin
                            filter.close_read
                            filter.print to_s
                            filter.close
                        rescue
                            nil
                        ensure
                            exit!
                        end
                    end
                end
            end
        end

        def process(&block) #:nodoc:
            begin
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
                            folderstyle MBox
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
            rescue Exception
                log "Error while executing rules: #{$!}"
                $@.each { |tr| log "Backtrace: #{tr}" }
                log "Attempting to save to spoolfile after error"
                folderstyle MBox
                save(spoolfile)
            end
        end
    end
end
