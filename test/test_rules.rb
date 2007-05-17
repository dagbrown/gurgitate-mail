require "test/gurgitate-test"

class TC_Rules < GurgitateTest
    def test_add_rules_normal
        rulesfile = File.join(@testdir, "rules_1.rb")
        File.open(rulesfile, File::CREAT|File::WRONLY) do |f|
            f.puts "nil"
        end

        assert @gurgitate.add_rules(rulesfile)

        assert_equal [rulesfile], @gurgitate.instance_variable_get("@rules")
    end

    def test_add_unreadable_rules
        rulesfile = File.join(@testdir, "rules_1.rb")
        File.open(rulesfile, File::CREAT|File::WRONLY) do |f|
            f.puts "nil"
        end

        FileUtils.chmod 0, rulesfile

        assert_equal false, @gurgitate.add_rules(rulesfile)
    end

    def test_add_nonexistent_rules
        rulesfile = File.join(@testdir, "rules_1.rb")
        assert_equal false, @gurgitate.add_rules(rulesfile)
    end

    def test_add_default_rules
        File.open File.join(@testdir,".gurgitate-rules.rb"), File::CREAT|File::WRONLY do |f|
            f.puts "nil"
        end

        assert_nothing_raised do
            @gurgitate.add_rules :default
        end

        assert_equal [File.join(@testdir,".gurgitate-rules.rb")],
            @gurgitate.instance_variable_get("@rules")
    end
end
