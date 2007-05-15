#!/opt/bin/ruby -w

#------------------------------------------------------------------------
# 
#------------------------------------------------------------------------

require 'test/unit'
require 'test/unit/ui/console/testrunner'
require 'stringio'

class TC_Header < Test::Unit::TestCase

    def setup
        require './gurgitate-mail'
    end

    # def teardown
    # end

    def test_simple_header
        h=Gurgitate::Header.new("From: fromheader@example.com")
        assert_equal(h.name,"From", "Simple header name is From")
        assert_equal(h.contents,"fromheader@example.com", 
            "Contents is fromheader@example.com")
        assert_equal(h.value,"fromheader@example.com", 
            "Contents is fromheader@example.com")
    end

    def test_canonicalize_crashing
        String.class_eval do
            alias old_capitalize capitalize
            def capitalize
                raise RuntimeError
            end
        end

        test_simple_header

        String.class_eval do
            alias capitalize old_capitalize
        end
    end


    # This is an illegal header that turns up in spam sometimes.
    # Crashing when you get spam is bad.
    def test_malcapitalized_header
        h=Gurgitate::Header.new("FROM: fromheader@example.com")
        assert_equal(h.name,"From", "Badly-capitalized header is From")
        assert_equal(h.contents,"fromheader@example.com", 
            "Badly-capitalized header")
        assert_equal(h.value,"fromheader@example.com", 
            "Badly-capitalized header")
    end

    # I got a message with "X-Qmail-Scanner-1.19" once.  I hate whoever did
    # that.
    def test_dot_in_header
        h=Gurgitate::Header.new("From.Header: fromheader@example.com")
        assert_equal(h.name, "From.header", 
                     "header with dot in it is From.header")
        assert_equal(h.contents, "fromheader@example.com",
                     "header with dot in it")
        assert_equal(h.value, "fromheader@example.com",
                     "header with dot in it")
    end

    # Dammit!  My new "anything goes" header parser was parsing too much
    def test_delivered_to
        h=Gurgitate::Header.new("Delivered-To: dagbrown@example.com")
        assert_equal("Delivered-To", h.name)
        assert_equal "dagbrown@example.com", h.contents
        assert_equal "dagbrown@example.com", h.value
    end

    # This is another particularly horrible spamware-generated not-a-header.
    def test_header_that_starts_with_hyphen
        h=Gurgitate::Header.new("-From: -fromheader@example.com")
        assert_equal(h.name, "-From",
                     "header with leading hyphen is -From")
        assert_equal(h.contents, "-fromheader@example.com",
                     "header with leading hyphen")
        assert_equal(h.value, "-fromheader@example.com",
                     "header with leading hyphen")
    end

    # This is another illegal header that turns up in spam sometimes.
    # Crashing when you get spam is bad.
    def test_nonalphabetic_initial_char_header
        h=Gurgitate::Header.new("2From: fromheader@example.com")
        assert_equal(h.name,"2from", 
                     "Header that starts with illegal char is 2From")
        assert_equal(h.contents, "fromheader@example.com",
                     "Header that starts with illegal char")
        assert_equal(h.value, "fromheader@example.com",
                     "Header that starts with illegal char")
    end

    def test_bad_headers
        assert_raises(Gurgitate::IllegalHeader,"Empty name") {
            h=Gurgitate::Header.new(": Hi")
        }
#         assert_raises(Gurgitate::IllegalHeader,"Empty header contents") {
#             h=Gurgitate::Header.new("From: ")
#         }
        assert_raises(Gurgitate::IllegalHeader,"Bad header syntax") {
            h=Gurgitate::Header.new("This is completely wrong")
        }
    end
    def test_extending_header
        h=Gurgitate::Header.new("From: fromheader@example.com")
        h << "  (Dave Brown)"
        assert_equal(h.name,"From","Extended header is From")
        assert_equal(h.contents,"fromheader@example.com\n  (Dave Brown)",
            "Extended header contains all data")
        assert_equal(h.contents,h.value,"Contents same as value")
    end

    def test_empty_header_with_extension
        h=Gurgitate::Header.new("From:")
        h << " fromheader@example.com"
        assert_equal("From",h.name,"Empty extended header is From")
        assert_equal("\n fromheader@example.com", h.contents,
                     "Empty extended header contains all data")
        assert_equal(h.contents, h.value, "Contents same as value")
    end

    def test_changing_header
        h=Gurgitate::Header.new("From: fromheader@example.com")
        h.contents="anotherfromheader@example.com"
        assert_equal(h.contents,"anotherfromheader@example.com",
            "header contents contains new data")
    end

    def test_tabseparated_header
        h=Gurgitate::Header.new("From:\tfromheader@example.com")
        assert_equal(h.name,"From","Tabseparated header is From (bug#154)")
        assert_equal(h.contents,"fromheader@example.com",
            "Tabseparated header's contents are correct (bug#154)")
        assert_equal(h.contents,h.value,"Contents same as value (bug#154)")
    end

    def test_conversion_to_String
        h=Gurgitate::Header.new("From: fromheader@example.com")
        assert_equal(h.to_s,"From: fromheader@example.com", "Conversion to string returns input")
    end

    def test_regex_match
        h=Gurgitate::Header.new("From: fromheader@example.com")
        assert_equal(0,h.matches(/fromheader/),"Matches regex that would match input")
        assert_equal(nil,h.matches(/notininput/),"Does not match regex that would not match input")
    end
end

