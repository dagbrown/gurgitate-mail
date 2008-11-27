require 'test/unit'
require 'test/unit/ui/console/testrunner'
require 'stringio'

class TC_Process < Test::Unit::TestCase

	def setup
        require "./gurgitate-mail"
		m = StringIO.new("From: me\nTo: you\nSubject: test\n\nHi.")
		@gurgitate = Gurgitate::Gurgitate.new(m)
	end
	
	def test_1
		assert_nothing_raised do
			@gurgitate.process { break }
			@gurgitate.process { pipe('cat > /dev/null') }
			@gurgitate.process { return }
		end
	end
end

