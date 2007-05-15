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

