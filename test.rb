#!/opt/bin/ruby -w

#------------------------------------------------------------------------
# 
#------------------------------------------------------------------------

require 'test/unit'
require 'test/unit/ui/console/testrunner'

class TC_Header < Test::Unit::TestCase

    def setup
        require './gurgitate-mail'
    end

    # def teardown
    # end

    def test_simple_header
        h=Gurgitate::Header.new("From: dagbrown@example.com")
        assert_equal(h.name,"From", "Simple header name is From")
        assert_equal(h.contents,"dagbrown@example.com", 
            "Contents is dagbrown@example.com")
        assert_equal(h.value,"dagbrown@example.com", 
            "Contents is dagbrown@example.com")
    end

    def test_malcapitalized_header
        h=Gurgitate::Header.new("FROM: dagbrown@example.com")
        assert_equal(h.name,"From", "Badly-capitalized header is From")
        assert_equal(h.contents,"dagbrown@example.com", 
            "Badly-capitalized header")
        assert_equal(h.value,"dagbrown@example.com", 
            "Badly-capitalized header")
    end

    def test_bad_headers
        assert_raises(Gurgitate::IllegalHeader,"Empty name") {
            h=Gurgitate::Header.new(": Hi")
        }
        assert_raises(Gurgitate::IllegalHeader,"Empty header contents") {
            h=Gurgitate::Header.new("From: ")
        }
        assert_raises(Gurgitate::IllegalHeader,"Bad header syntax") {
            h=Gurgitate::Header.new("This is completely wrong")
        }
    end
end

class TC_Headers < Test::Unit::TestCase
    def setup
        require './gurgitate-mail'
    end

    def test_single_header
        h=Gurgitate::Headers.new(<<'EOF'
From fromline@example.com Sat Sep 27 12:20:25 PDT 2003
From: fromheader@example.com
EOF
        )
        assert_equal("fromline@example.com",h.from)
        assert_equal(1,h["From"].length)
        assert_equal("From",h["From"][0].name)
        assert_equal("fromheader@example.com",h["From"][0].contents)
    end

    def test_fromline_simple_username
        h=Gurgitate::Headers.new(<<'EOF'
From fromline Sat Sep 27 12:20:25 PDT 2003
From: fromheader@example.com
EOF
        )
        assert_equal("fromline",h.from)
        assert_equal(1,h["From"].length)
        assert_equal("From",h["From"][0].name)
        assert_equal("fromheader@example.com",h["From"][0].contents)
    end

    def test_fromline_no_username
        h=Gurgitate::Headers.new(<<'EOF'
From  Sat Sep 27 12:20:25 PDT 2003
From: fromheader@example.com
EOF
        )
        assert_equal("",h.from)
        assert_equal(1,h["From"].length)
        assert_equal("From",h["From"][0].name)
        assert_equal("fromheader@example.com",h["From"][0].contents)
    end

    def test_missing_fromline
        h=Gurgitate::Headers.new(<<'EOF'
From: fromheader@example.com
EOF
        )
        assert_equal('fromheader@example.com',h.from)
        assert_equal(1,h["From"].length)
        assert_equal("From",h["From"][0].name)
        assert_equal("fromheader@example.com",h["From"][0].contents)
    end

    def test_multiple_headers
        h=Gurgitate::Headers.new(<<'EOF'
From fromline@example.com Sat Sep 27 12:20:25 PDT 2003
From: fromheader@example.com
To: toheader@example.com
Subject: Subject line
EOF
        )
        assert_equal(h.from,"fromline@example.com")
        assert_equal(1,h["From"].length)
        assert_equal("From",h["From"][0].name)
        assert_equal("fromheader@example.com",h["From"][0].contents)
        assert_equal(1,h["To"].length)
        assert_equal("To",h["To"][0].name)
        assert_equal("toheader@example.com",h["To"][0].contents)
        assert_equal(1,h["Subject"].length)
        assert_equal("Subject",h["Subject"][0].name)
        assert_equal("Subject line",h["Subject"][0].contents)
    end

    def test_missing_fromline
        h=Gurgitate::Headers.new(<<'EOF'
From: fromheader@example.com
To: toheader@example.com
Subject: Subject line
EOF
        )
        assert_equal('fromheader@example.com',h.from)
        assert_equal(1,h["From"].length)
        assert_equal("From",h["From"][0].name)
        assert_equal("fromheader@example.com",h["From"][0].contents)
        assert_equal(1,h["To"].length)
        assert_equal("To",h["To"][0].name)
        assert_equal("toheader@example.com",h["To"][0].contents)
        assert_equal(1,h["Subject"].length)
        assert_equal("Subject",h["Subject"][0].name)
        assert_equal("Subject line",h["Subject"][0].contents)
    end
end

def runtests
    Test::Unit::UI::Console::TestRunner.run(TC_Header)
    Test::Unit::UI::Console::TestRunner.run(TC_Headers)
end

if __FILE__ == $0 then
    runtests
end
