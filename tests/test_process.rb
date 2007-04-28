require 'test/unit'
require 'test/unit/ui/console/testrunner'
require 'stringio'
require 'fileutils'
require "./gurgitate-mail"

class TC_Process < Test::Unit::TestCase

	def setup
        @testdir = File.join(File.dirname(__FILE__),"..","test-data")
        FileUtils.rm_rf @testdir if File.exists? @testdir
        Dir.mkdir @testdir
		m = StringIO.new("From: me\nTo: you\nSubject: test\n\nHi.")
		@gurgitate = Gurgitate::Gurgitate.new(m)
        testdir = @testdir
        @gurgitate.instance_eval do 
            sendmail "/bin/cat" 
            spooldir testdir
            spoolfile File.join(testdir, "default")
        end
        @spoolfile = File.join(testdir, "default")
	end

    def teardown
        FileUtils.rm_rf @testdir
    end
	
    def test_basic_delivery
        assert_nothing_raised do
            @gurgitate.process { return }
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
        assert_equal("Hi.", @gurgitate.body)
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

        assert_equal("From: me", mess.header("From"))
        assert_equal("To: you", mess.header("To"))
        assert_equal("Subject: test", mess.header("Subject"))
        assert_equal("Hi.", mess.body)
        puts File.read(@spoolfile)
    end
end

