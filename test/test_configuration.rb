# -*- encoding : utf-8 -*-
builddir = File.dirname(File.dirname(__FILE__))

unless $:[0] == builddir
    $:.unshift builddir
end

require "test/gurgitate-test"
require "etc"

class TC_Configuration < GurgitateTest
    def test_default_configuration
        assert_equal Gurgitate::Deliver::MBox, @gurgitate.folderstyle
        assert_equal @folders, @gurgitate.maildir
        assert_equal @spoolfile, @gurgitate.spoolfile
        assert_equal @testdir, @gurgitate.homedir
    end

    def test_changing_folderstyle_to_maildir
        assert_nothing_raised do
            @gurgitate.folderstyle Gurgitate::Deliver::Maildir
        end
        assert_equal File.join(@testdir,"Maildir"), @gurgitate.spoolfile
        assert_equal File.join(@testdir,"Maildir"), @gurgitate.maildir
    end

    def test_changing_folderstyle_to_mbox
        assert_nothing_raised do
            @gurgitate.folderstyle Gurgitate::Deliver::MBox
        end

        assert_equal "/var/spool/mail", @gurgitate.spooldir
        assert_equal File.join("/var/spool/mail",
                               Etc.getpwuid.name), @gurgitate.spoolfile
    end

    def test_illegal_folderstyle_syntax
        assert_raises ArgumentError do
            @gurgitate.folderstyle 1, 2, 3
        end
    end
end

