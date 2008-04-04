require 'test/unit'
require 'test/unit/ui/console/testrunner'
require 'stringio'
require 'fileutils'
require 'pathname'
require 'irb'
$:.unshift File.dirname(__FILE__) + "/.."
require "gurgitate-mail"

class GurgitateTest < Test::Unit::TestCase
	def setup
        currentdir = Pathname.new(File.join(File.dirname(__FILE__), 
                                         "..")).realpath.to_s
        @testdir = File.join(currentdir,"test-data")
        @folders = File.join(@testdir,"folders")
        FileUtils.rmtree @testdir if File.exists? @testdir
        Dir.mkdir @testdir
        Dir.mkdir @folders
		m = StringIO.new("From: me\nTo: you\nSubject: test\n\nHi.\n")
        @gurgitate = nil
		@gurgitate = Gurgitate::Gurgitate.new(m)
        testdir = @testdir
        folders = @folders
        @gurgitate.instance_eval do 
            sendmail "/bin/cat" 
            homedir testdir
            spooldir testdir
            spoolfile File.join(testdir, "default")
            maildir folders
        end
        @spoolfile = File.join(testdir, "default")
	end

    def maildirmake mailbox # per the UNIX command
        FileUtils.mkdir mailbox
        %w/cur tmp new/.each do |subdir|
            FileUtils.mkdir File.join(mailbox, subdir)
        end
    end

    def mhdirmake mailbox # per "maildirmake"
        FileUtils.mkdir mailbox
    end

    def teardown
        FileUtils.rmtree @testdir
    end

    def test_truth
        assert true
    end
end
