require 'test/unit'
require 'test/unit/ui/console/testrunner'
require 'stringio'
require 'fileutils'
require 'pathname'
require 'irb'
require "./gurgitate-mail"

class TC_Process < Test::Unit::TestCase

	def setup
        currentdir = Pathname.new(File.join(File.dirname(__FILE__), 
                                         "..")).realpath.to_s
        @testdir = File.join(currentdir,"test-data")
        @folders = File.join(@testdir,"folders")
        FileUtils.rmtree @testdir if File.exists? @testdir
        Dir.mkdir @testdir
        Dir.mkdir @folders
		m = StringIO.new("From: me\nTo: you\nSubject: test\n\nHi.\n")
        @gurgitate = nil
		@gurgitate = Gurgitate::Gurgitate.new(m)
        testdir = @testdir
        folders = @folders
        @gurgitate.instance_eval do 
            sendmail "/bin/cat" 
            spooldir testdir
            spoolfile File.join(testdir, "default")
            maildir folders
        end
        @spoolfile = File.join(testdir, "default")
	end

    def maildirmake mailbox # per the command
        FileUtils.mkdir mailbox
        %w/cur tmp new/.each do |subdir|
            FileUtils.mkdir File.join(mailbox, subdir)
        end
    end

    def teardown
        FileUtils.rmtree @testdir
    end

    #************************************************************************
    # tests
    #************************************************************************

    def test_basic_delivery
        assert_nothing_raised do
            @gurgitate.process { nil }
        end
        assert File.exists?(@spoolfile)
    end

    def test_detect_mbox
        Dir.mkdir(@testdir) rescue nil
        File.open(@spoolfile, File::WRONLY | File::CREAT) do |f|
            f.print ""
        end

        assert_nothing_raised do
            @gurgitate.process { nil }
        end

        assert File.exists?(@spoolfile)
    end

    def test_detect_maildir
        maildirmake @spoolfile

        assert_nothing_raised do
            @gurgitate.process { nil }
        end

        assert Dir[File.join(@spoolfile,"new","*")].length > 0
        assert File.exists?(Dir[File.join(@spoolfile,"new","*")][0])
        FileUtils.rmtree @spoolfile
        teardown
        test_detect_mbox
        setup
    end

    def test_pipe_raises_no_exceptions
		assert_nothing_raised do
			@gurgitate.process { pipe('cat > /dev/null') }
		end
    end

    def test_break_does_not_deliver
		assert_nothing_raised do
			@gurgitate.process { break }
		end

        assert !File.exists?(@spoolfile)
    end

    def test_save_folders
        assert_nothing_raised do
            @gurgitate.process do
                save "=test"
                break
            end
        end

        assert File.exists?(File.join(@folders, "test"))
        assert File.stat(File.join(@folders, "test")).file?
    end

    def test_save_guess_maildir
        maildirmake File.join(@folders,"test")

        assert File.exists?(File.join(@folders, "test"))
        assert File.stat(File.join(@folders, "test")).directory?
        assert File.exists?(File.join(@folders, "test", "new"))

        assert_equal 0, Dir[File.join(@folders, "test", "new", "*")].length
        assert_equal 0, Dir[File.join(@folders, "test", "cur", "*")].length

        assert_nothing_raised do
            @gurgitate.process do
                save "=test"
                break
            end
        end

        assert File.exists?(File.join(@folders, "test"))
        assert File.stat(File.join(@folders, "test")).directory?
        assert File.exists?(File.join(@folders, "test", "new"))
        assert File.stat(File.join(@folders, "test","new")).directory?
        assert_equal 0, Dir[File.join(@folders, "test", "cur", "*")].length
        assert_equal 1, Dir[File.join(@folders, "test", "new", "*")].length
    end

    def test_save_maildir_collision
        maildirmake File.join(@folders,"test")

        assert File.exists?(File.join(@folders, "test"))
        assert File.stat(File.join(@folders, "test")).directory?
        assert File.exists?(File.join(@folders, "test", "new"))

        assert_equal 0, Dir[File.join(@folders, "test", "new", "*")].length
        assert_equal 0, Dir[File.join(@folders, "test", "cur", "*")].length

        assert_nothing_raised do
            @gurgitate.process do
                save "=test"
                save "=test"
                break
            end
        end

        assert File.exists?(File.join(@folders, "test"))
        assert File.stat(File.join(@folders, "test")).directory?
        assert File.exists?(File.join(@folders, "test", "new"))
        assert File.stat(File.join(@folders, "test","new")).directory?
        assert_equal 0, Dir[File.join(@folders, "test", "cur", "*")].length
        assert_equal 2, Dir[File.join(@folders, "test", "new", "*")].length
    end

    def test_save_create_maildir
        maildirmake @spoolfile

        assert_nothing_raised do
            @gurgitate.process do
                @folderstyle = Gurgitate::Deliver::Maildir
                @maildir = @spoolfile
                save "=test"
                break
            end
        end

        assert File.exists?(File.join(@spoolfile, ".test"))
        assert File.stat(File.join(@spoolfile, ".test")).directory?
        assert File.exists?(File.join(@spoolfile, ".test", "new"))
        assert File.stat(File.join(@spoolfile, ".test","new")).directory?
        assert_equal 0, Dir[File.join(@spoolfile, ".test", "cur", "*")].length
        assert_equal 1, Dir[File.join(@spoolfile, ".test", "new", "*")].length
    end

    def test_save_bad_filename
        assert_nothing_raised do
            @gurgitate.process do
                save "test"
            end
        end

        assert File.exists? @spoolfile
        assert !File.exists?("test")
    end

    def test_cannot_save
        FileUtils.touch @spoolfile
        FileUtils.chmod 0, @spoolfile

        assert_raises Errno::EACCES do
            @gurgitate.process do 
                nil
            end
        end
    end

    def test_mailbox_heuristics_mbox
        @gurgitate.instance_eval do
            @folderstyle = nil
        end

        assert_nothing_raised do
            @gurgitate.process do
                save "=test"
            end
        end

        assert File.exists?(File.join(@folders, "test"))
        assert File.stat(File.join(@folders, "test")).file?
    end

    def test_mailbox_heuristics_maildir
        @gurgitate.instance_eval do
            @folderstyle = nil
        end

        assert_nothing_raised do
            @gurgitate.process do
                save "=test/"
            end
        end

        assert File.exists?(File.join(@folders, "test"))
        assert File.stat(File.join(@folders, "test")).directory?
        assert File.exists?(File.join(@folders, "test", "new"))
        assert File.stat(File.join(@folders, "test","new")).directory?
        assert_equal 0, Dir[File.join(@folders, "test", "cur", "*")].length
        assert_equal 1, Dir[File.join(@folders, "test", "new", "*")].length
    end

    def test_message_parsed_correctly
        assert_equal("From: me",@gurgitate.header("From"))
        assert_equal("To: you", @gurgitate.header("To"))
        assert_equal("Subject: test", @gurgitate.header("Subject"))
        assert_equal("Hi.\n", @gurgitate.body, "Message body is wrong")
    end

    def test_message_written_correctly
        test_message_parsed_correctly
        assert_nothing_raised do
            @gurgitate.process
        end

        mess=nil
        assert_nothing_raised do
            mess = Gurgitate::Mailmessage.new(File.read(@spoolfile))
        end

        assert_equal("From: me", mess.header("From"), "From header is wrong")
        assert_equal("To: you", mess.header("To"), "To header is wrong")
        assert_equal("Hi.\n", mess.body, "Body is wrong")
        assert_equal("Subject: test", mess.header("Subject"), "Subject header wrong")
    end
end

