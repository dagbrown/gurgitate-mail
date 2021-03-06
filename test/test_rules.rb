# -*- encoding : utf-8 -*-
builddir = File.join(File.dirname(__FILE__),"..")

puts builddir

unless $:[0] == builddir
    $:.unshift builddir
end

require "test/gurgitate-test"
require "etc"

class TC_Rules < GurgitateTest
    def setup
        super
        @rulesfile = File.join(@testdir, "rules_1.rb")
        File.open(rulesfile, File::CREAT|File::WRONLY) do |f|
            f.puts "nil"
        end
        
        @defaultrules = File.join(@testdir, ".gurgitate-rules.rb")
        File.open File.join(@defaultrules), File::CREAT|File::WRONLY do |f|
            f.puts "nil"
        end
    end

    attr_reader :rulesfile

    def teardown
        File.unlink rulesfile if File.exist? rulesfile
    end

    def test_add_rules_normal
        assert @gurgitate.add_rules(rulesfile)

        assert_equal [rulesfile], @gurgitate.instance_variable_get("@rules")
    end

    def test_add_unreadable_rules
        FileUtils.chmod 0, rulesfile

        assert_equal false, @gurgitate.add_rules(rulesfile)
    end

    def test_add_nonexistent_rules
        File.unlink rulesfile
        assert_equal false, @gurgitate.add_rules(rulesfile)
    end

    def test_add_default_rules
        assert_nothing_raised do
            @gurgitate.add_rules :default
        end

        assert_equal [@defaultrules],
            @gurgitate.instance_variable_get("@rules")
    end

    def test_add_system_rules
        unless Etc.getpwuid.uid == 0
            assert_equal false, @gurgitate.add_rules(rulesfile, :system => true)
        else
            # but really, fer crying out loud, DON'T RUN TESTS AS ROOT
            assert true, @gurgitate.add_rules(rulesfile, :system => true)
        end
    end

    def test_add_user_rules
        assert @gurgitate.add_rules(rulesfile, :user => true)
    end

    def test_add_user_rules_file_not_found
        File.unlink rulesfile
        assert_equal false, @gurgitate.add_rules(rulesfile, :user => true)
    end

    def test_bad_syntax
        assert_raises ArgumentError do
            @gurgitate.add_rules(rulesfile, :honk)
        end
    end
end

class TC_ExecuteRules < TC_Rules
    def setup
        super
        @invalidrules = File.join(@testdir, "rules_invalid.rb")
        File.open @invalidrules, "w" do |f|
            f.puts "invalid syntax"
        end
        @exceptionrules = File.join(@testdir, "rules_exception.rb")
        File.open @exceptionrules, "w" do |f|
            f.puts "raise RuntimeError, 'testing'"
        end
    end

    def teardown
        File.unlink @invalidrules if File.exists? @invalidrules
    end

    def test_process_default
        @gurgitate.add_rules :default
        assert_nothing_raised do
            @gurgitate.process
        end
    end

    def test_process_rules_not_found
        @gurgitate.add_rules @rulesfile
        File.unlink @rulesfile
        assert_nothing_raised do
            @gurgitate.process
        end
        assert File.exists?(@spoolfile)
    end
end

