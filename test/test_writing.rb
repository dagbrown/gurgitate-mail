# -*- encoding : utf-8 -*-
builddir = File.join(File.dirname(__FILE__),"..")

unless $:[0] == builddir
    $:.unshift builddir
end

require 'rubygems'
gem 'test-unit'
require 'test/unit'
require 'test/unit/ui/console/testrunner'
require 'stringio'

class TC_Writing < Test::Unit::TestCase
    def setup
        require 'gurgitate-mail'
    end

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

    def test_initialization_headers_only
        mess = Gurgitate::Mailmessage.create :from => "test@test", :to => "test2@test2"
        assert_equal [ "From: test@test", "To: test2@test2" ], 
            mess.headers.to_s.split(/\n/)
    end

    def test_initialization_headers_and_body
        mess = Gurgitate::Mailmessage.create "This is a test", 
            :from => "test@test", 
            :to => "test2@test"
        assert_equal "This is a test", mess.body
        assert_equal [ "From: test@test", "To: test2@test" ], 
            mess.headers.to_s.split(/\n/)
    end

    def test_initialization_headers_body_in_initialization_hash
        mess = Gurgitate::Mailmessage.create :body => "This is a test", 
            :from => "test@test", 
            :to => "test2@test"
        assert_equal "This is a test", mess.body
        assert_equal [ "From: test@test", "To: test2@test" ], 
            mess.headers.to_s.split(/\n/)
    end

    def test_creation_round_trip
        mess = Gurgitate::Mailmessage.create "This is a test", 
            :from => "test@test",
            :to => "test2@test2",
            :subject => "Test subject"
        reparsed_mess = Gurgitate::Mailmessage.new(mess.to_s)
        assert_equal reparsed_mess.to_s, mess.to_s
    end

    def test_creation_sender_specified
        mess = Gurgitate::Mailmessage.create :body => "This is a test",
            :from => "from@test",
            :to => "to@test",
            :sender => "sender@test"
        assert_equal "This is a test", mess.body
        assert_equal "From: from@test", mess.headers["From"].to_s
        assert_equal "To: to@test", mess.headers["To"].to_s
        assert_equal "sender@test", mess.from
    end

    def test_creation_recipient_specified
        mess = Gurgitate::Mailmessage.create :body => "This is a test",
            :from => "from@test",
            :to => "to@test",
            :recipient => "recipient@test"
        assert_equal "This is a test", mess.body
        assert_equal "From: from@test", mess.headers["From"].to_s
        assert_equal "To: to@test", mess.headers["To"].to_s
        assert_equal "recipient@test", mess.to
    end

    def test_creation_sender_not_specified
        mess = Gurgitate::Mailmessage.create :body => "This is a test",
            :from => "from@test",
            :to => "to@test"
        assert_equal "This is a test", mess.body
        assert_equal "From: from@test", mess.headers["From"].to_s
        assert_equal "To: to@test", mess.headers["To"].to_s
        assert_equal "", mess.from
        assert_equal "to@test", mess.to
    end

    def test_creation_incrementally
        mess = Gurgitate::Mailmessage.create
        mess.sender = "sender@test"
        mess.recipient = "recipient@test"
        mess.body = "This is a test"
        mess.headers["From"] = "from@test"
        mess.headers["To"] = "to@test"

        assert_equal "sender@test", mess.from
        assert_equal "recipient@test", mess.to
        assert_equal "This is a test", mess.body
        assert_equal "From: from@test", (mess.headers["From"]).to_s
        assert_equal "To: to@test", (mess.headers["To"]).to_s
    end
end

