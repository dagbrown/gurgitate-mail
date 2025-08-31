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
require "gurgitate-mail"

class TC_Gurgitate_delivery < GurgitateTest
    def ensure_empty_maildir(dir)
        assert File.exist?(dir)
        assert File.stat(dir).directory?
        assert File.exist?(File.join(dir, "new"))

        assert_equal 0, Dir[File.join(dir, "new", "*")].length
        assert_equal 0, Dir[File.join(dir, "cur", "*")].length
    end

    def ensure_maildir_with_n_messages(dir, n)
        assert File.exist?(dir)
        assert File.stat(dir).directory?
        assert File.exist?(File.join(dir, "new"))
        assert File.stat(File.join(dir, "new")).directory?
        assert_equal 0, Dir[File.join(dir, "cur", "*")].length
        assert_equal n, Dir[File.join(dir, "new", "*")].length
    end

    def ensure_empty_mhdir(dir)
        assert File.exist?(dir)
        assert File.stat(dir).directory?

        assert_equal 0, Dir[File.join(dir, "*")].length
    end

    def ensure_mhdir_with_messages(dir, *messages)
        assert File.exist?(dir)
        assert File.stat(dir).directory?
        messages.each do |message|
            assert File.exist?(File.join(dir, message.to_s))
            assert File.stat(File.join(dir,message.to_s)).file?
        end
    end

    #************************************************************************
    # tests
    #************************************************************************
    def test_basic_delivery
        assert_nothing_raised do
            @gurgitate.process { nil }
        end
        assert File.exist?(@spoolfile)
    end

    def test_detect_mbox
        Dir.mkdir(@testdir) rescue nil
        File.open(@spoolfile, File::WRONLY | File::CREAT) do |f|
            f.print ""
        end

        assert_nothing_raised do
            @gurgitate.process { nil }
        end

        assert File.exist?(@spoolfile)
    end

    def test_detect_maildir
        maildirmake @spoolfile

        assert_nothing_raised do
            @gurgitate.process { nil }
        end

        assert Dir[File.join(@spoolfile,"new","*")].length > 0
        assert File.exist?(Dir[File.join(@spoolfile,"new","*")][0])
        FileUtils.rmtree @spoolfile
        teardown
        test_detect_mbox
        setup
    end

    def test_detect_mhdir
        mhdirmake @spoolfile

        assert_nothing_raised do
            @gurgitate.process { nil }
        end

        assert File.exist?(@spoolfile)
        assert File.directory?(@spoolfile)
        assert File.exist?(File.join(@spoolfile,"1"))
        assert File.exist?(File.join(@spoolfile,".mh_sequences"))
        FileUtils.rmtree @spoolfile
        teardown
        test_detect_mbox
        setup
    end

    def test_save_folders
        assert_nothing_raised do
            @gurgitate.process do
                save "=test"
                break
            end
        end

        assert File.exist?(File.join(@folders, "test"))
        assert File.stat(File.join(@folders, "test")).file?
    end

    def test_save_guess_maildir
        maildirmake File.join(@folders,"test")

        ensure_empty_maildir File.join(@folders, "test")

        assert_nothing_raised do
            @gurgitate.process do
                save "=test"
                break
            end
        end

        ensure_maildir_with_n_messages(File.join(@folders, "test"), 1)
    end

    def test_save_guess_mh
        mhdirmake File.join(@folders,"test")

        ensure_empty_mhdir File.join(@folders, "test")

        assert_nothing_raised do
            @gurgitate.process do
                save "=test"
                break
            end
        end

        ensure_mhdir_with_messages(File.join(@folders,"test"),1)
        assert File.exist?(File.join(@folders, "test", ".mh_sequences"))
        assert File.stat(File.join(@folders, "test", ".mh_sequences")).file?
        assert_equal "unseen: 1\n", 
            File.read(File.join(@folders, "test", ".mh_sequences"))
    end

    def test_save_maildir_collision
        maildirmake File.join(@folders,"test")

        ensure_empty_maildir(File.join(@folders, "test"))

        assert_nothing_raised do
            @gurgitate.process do
                save "=test"
                save "=test"
                break
            end
        end

        ensure_maildir_with_n_messages(File.join(@folders,"test"),2)
    end

    def test_save_mh_collision
        mhdirmake File.join(@folders,"test")

        ensure_empty_mhdir File.join(@folders,"test")

        assert_nothing_raised do
            @gurgitate.process do
                save "=test"
                save "=test"
                break
            end
        end

        ensure_mhdir_with_messages(File.join(@folders, "test"), 1, 2)

        assert File.exist?(File.join(@folders, "test", ".mh_sequences"))
        assert File.stat(File.join(@folders, "test", ".mh_sequences")).file?
        assert_equal "unseen: 1-2\n", 
            File.read(File.join(@folders, "test", ".mh_sequences"))
    end

    def test_save_create_maildir
        maildirmake @spoolfile

        assert_nothing_raised do
            @gurgitate.process do
                @folderstyle = Gurgitate::Deliver::Maildir
                @maildir = @spoolfile
                save "=test"
                break
            end
        end

        ensure_maildir_with_n_messages(File.join(@spoolfile,".test"),1)
    end

    def test_save_create_mh
        maildirmake @spoolfile

        assert_nothing_raised do
            @gurgitate.process do
                @folderstyle = Gurgitate::Deliver::MH
                @maildir = @spoolfile
                save "=test"
                break
            end
        end

        ensure_mhdir_with_messages(File.join(@spoolfile,"test"),1)
        assert File.exist?(File.join(@spoolfile, "test", ".mh_sequences"))
        assert File.stat(File.join(@spoolfile, "test",".mh_sequences")).file?
    end

    def test_save_bad_filename
        assert_nothing_raised do
            @gurgitate.process do
                save "testing"
            end
        end

        assert File.exist?(@spoolfile)
        assert !File.exist?("testing")
    end

    def test_cannot_save
        FileUtils.touch @spoolfile
        FileUtils.chmod 0, @spoolfile

        assert_raises Errno::EACCES do
            @gurgitate.process do 
                nil
            end
        end
    end

    def test_mailbox_heuristics_mbox
        @gurgitate.instance_eval do
            @folderstyle = nil
        end

        assert_nothing_raised do
            @gurgitate.process do
                save "=test"
            end
        end

        assert File.exist?(File.join(@folders, "test"))
        assert File.stat(File.join(@folders, "test")).file?
    end

    def test_mailbox_heuristics_maildir
        @gurgitate.instance_eval do
            @folderstyle = nil
        end

        assert_nothing_raised do
            @gurgitate.process do
                save "=test/"
            end
        end

        ensure_maildir_with_n_messages(File.join(@folders, "test"), 1)
    end

    def test_message_parsed_correctly
        assert_equal("From: me",@gurgitate.header("From"))
        assert_equal("To: you", @gurgitate.header("To"))
        assert_equal("Subject: test", @gurgitate.header("Subject"))
        assert_equal("Hi.\n", @gurgitate.body, "Message body is wrong")
    end

    def test_message_written_correctly
        test_message_parsed_correctly
        assert_nothing_raised do
            @gurgitate.process
        end

        mess=nil
        assert_nothing_raised do
            mess = Gurgitate::Mailmessage.new(File.read(@spoolfile))
        end

        assert_equal("From: me", mess.header("From"), "From header is wrong")
        assert_equal("To: you", mess.header("To"), "To header is wrong")
        assert_equal("Hi.\n", mess.body, "Body is wrong")
        assert_equal("Subject: test", mess.header("Subject"), "Subject header wrong")
    end
end

