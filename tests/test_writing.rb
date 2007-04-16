#/opt/bin/ruby -w

require 'test/unit'
require 'test/unit/ui/console/testrunner'
require 'stringio'

class TC_Writing < Test::Unit::TestCase
    def test_null_message
        mess = nil
        assert_nothing_raised do
            mess = Gurgitate::Mailmessage.new
        end
    end
end
