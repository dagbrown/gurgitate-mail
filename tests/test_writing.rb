#/opt/bin/ruby -w

require 'test/unit'
require 'test/unit/ui/console/testrunner'
require 'stringio'

class TC_Writing < Test::Unit::TestCase
    def test_null_message
        assert_nothing_raised do
            Gurgitate::Mailmessage.new
        end
    end

    def test_one_header_message
        mess = Gurgitate::Mailmessage.new
        mess.headers["From"] = "test@test"
        assert_equal "From: test@test",  mess.headers.to_s
        assert_equal "From: test@test\n\n", mess.to_s
    end

    def test_two_headers_message
        mess = Gurgitate::Mailmessage.new
        mess.headers["From"] = "test@test"
        mess.headers["To"]   = "test2@test2"
        assert_equal "From: test@test\nTo: test2@test2",  mess.headers.to_s
    end
end
