# -*- encoding : utf-8 -*-
require 'rubygems'
gem 'test-unit'
require 'test/unit'
require 'test/unit/ui/console/testrunner'
require 'stringio'

builddir = File.join(File.dirname(__FILE__),"..")

unless $:[0] == builddir
    $:.unshift builddir
end

class TC_Headers_meddling_with_headers < Test::Unit::TestCase
    def setup
        $:.unshift File.dirname(__FILE__)
        require "gurgitate/headers"

        @message = <<'EOF'
From: fromline@example.com
To: toline@example.com
Subject: Subject Line
EOF

        @headers = Gurgitate::Headers.new @message
    end

    def test_match
        assert @headers.match("From", /example.com/)
    end

    def test_nomatch
        assert !@headers.match("From", /lart.ca/)
    end

    def test_match_regex
        result = nil
        assert_nothing_raised do
            result = @headers.match "From", /example.com/
        end
        assert result
    end

    def test_match_string
        result = nil

        assert_nothing_raised do
            assert result = @headers.match("From", "example.com")
        end

        assert result
        result = nil

        assert_nothing_raised do
            result = @headers.match("From", "e.ample.com")
        end

        assert !result
    end
end

