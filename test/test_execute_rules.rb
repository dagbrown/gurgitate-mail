builddir = File.join(File.dirname(__FILE__),"..")

unless $:[0] == builddir
    $:.unshift builddir
end

require "test/gurgitate-test"
require "test/test_rules"
require "etc"

class TC_Execute_rules < TC_Rules
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
