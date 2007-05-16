require 'test/unit'
require 'test/unit/ui/console/testrunner'
require 'stringio'
require 'fileutils'
require 'pathname'
require 'irb'
require "./gurgitate-mail"

class TC_Process < GurgitateTest
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

    def test_method_missing
        assert_equal "test", @gurgitate.subject[0].contents
        assert_raises NameError do
            p @gurgitate.nonexistentheader
        end
    end
end
