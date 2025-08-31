# -*- encoding : utf-8 -*-
builddir = File.dirname(File.dirname(__FILE__))

unless $:[0] == builddir
    $:.unshift builddir
end

require 'rubygems'
gem 'test-unit'
require 'test/unit'
require 'test/unit/ui/console/testrunner'
require 'stringio'
require 'fileutils'
require 'pathname'
require 'irb'
require "test/gurgitate-test"
require "gurgitate/deliver"

class DeliverTest
    include Gurgitate::Deliver

    attr_accessor :folderstyle

    def to_mbox
        "From test\n" + to_s
    end

    def to_s
        "From: test\nTo:test\nSubject: test\n\nTest\n"
    end
end

class TC_Deliver < Test::Unit::TestCase
    def setup
        currentdir = Pathname.new(File.join(File.dirname(__FILE__), 
                                         "..")).realpath.to_s
        @testdir = File.join(currentdir,"test-data")
        @folders = File.join(@testdir,"folders")
        FileUtils.rmtree @testdir if File.exist? @testdir
        Dir.mkdir @testdir
        Dir.mkdir @folders
		m = StringIO.new("From: me\nTo: you\nSubject: test\n\nHi.\n")
        @deliver_test = DeliverTest.new
        testdir = @testdir
        folders = @folders
        @deliver_test.folderstyle = Gurgitate::Deliver::MBox
        @spoolfile = File.join(testdir, "default")
    end

    def teardown
        FileUtils.rmtree @testdir
    end

    # ------------------------------------------------------------------------
    # And the tests
    # ------------------------------------------------------------------------
    def test_setup_worked
        assert true
    end
    
    def test_basic_deliver
        assert_nothing_raised do
            @deliver_test.save(@spoolfile)
        end
        assert File.exist?(@spoolfile)
        assert File.file?(@spoolfile)
        assert_equal File.read(@spoolfile), @deliver_test.to_mbox
    end

    def test_basic_delivery_maildir
        @deliver_test.folderstyle = Gurgitate::Deliver::Maildir
        assert_nothing_raised do
            @deliver_test.save(@spoolfile)
        end
        assert File.exist?(@spoolfile)
        assert File.directory?(@spoolfile)
        assert File.exist?(File.join(@spoolfile,"cur"))
        assert File.exist?(File.join(@spoolfile,"new"))
        assert File.exist?(File.join(@spoolfile,"tmp"))
        contents = Dir[File.join(@spoolfile,"new","*")]
        assert contents.length == 1
        assert File.exist?(contents[0])
        assert_equal File.read(contents[0]), @deliver_test.to_s
    end

    def test_basic_delivery_mh
        @deliver_test.folderstyle = Gurgitate::Deliver::MH
        assert_nothing_raised do
            @deliver_test.save(@spoolfile)
        end

        assert File.exist?(@spoolfile)
        assert File.directory?(@spoolfile)
        
        mess = File.join(@spoolfile,"1")
        seq  = File.join(@spoolfile,".mh_sequences")
        assert File.exist?(mess)
        assert File.exist?(seq)
        assert_equal File.read(mess), @deliver_test.to_s
        assert_equal File.read(seq), "unseen: 1\n"
    end
end

