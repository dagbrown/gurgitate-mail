require 'test/unit'
require 'test/unit/ui/console/testrunner'
require 'stringio'
require 'fileutils'
require 'pathname'
require 'irb'
require "./gurgitate-mail"

class GurgitateTest < Test::Unit::TestCase
	def setup
        currentdir = Pathname.new(File.join(File.dirname(__FILE__), 
                                         "..")).realpath.to_s
        @testdir = File.join(currentdir,"test-data")
        testdir = @testdir
        @folders = File.join(@testdir,"folders")
        folders = @folders
        FileUtils.rmtree @testdir if File.exists? @testdir
        Dir.mkdir @testdir
        Dir.mkdir @folders
		m = StringIO.new("From: me\nTo: you\nSubject: test\n\nHi.\n")
        @gurgitate = nil
		@gurgitate = Gurgitate::Gurgitate.new(m)

        @sendmail = File.join(@testdir, "bin", "sendmail")
        sendmail = @sendmail

        Dir.mkdir File.join(@testdir,"bin")

        File.open(@sendmail,"w") do |f|
            f.puts "#!/bin/sh"
            f.puts "exec > #{@testdir}/sendmail_output 2>&1"
            f.puts 'echo "$@"'
            f.puts 'cat'
        end

        FileUtils.chmod 0755, @sendmail

        @gurgitate.instance_eval do 
            sendmail "/bin/cat" 
            homedir testdir
            spooldir testdir
            spoolfile File.join(testdir, "default")
            maildir folders
        end
        @spoolfile = File.join(testdir, "default")
	end

    def maildirmake mailbox # per the command
        FileUtils.mkdir mailbox
        %w/cur tmp new/.each do |subdir|
            FileUtils.mkdir File.join(mailbox, subdir)
        end
    end

    def teardown
        FileUtils.rmtree @testdir
    end

    def test_truth
        assert true
    end
end
