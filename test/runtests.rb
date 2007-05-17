#!/opt/bin/ruby -w

#------------------------------------------------------------------------
# Unit tests for gurgitate-mail
#------------------------------------------------------------------------

require 'test/unit'
require 'test/unit/ui/console/testrunner'
require 'stringio'

def runtests(testcases)
    testcases.each do |testcase|
        Test::Unit::UI::Console::TestRunner.run testcase
    end
end

testcases = Dir[File.join("test","test_*")].map do |file|
    load file
    eval("TC_" + File.basename(file,".rb").sub(/^test_/,'').capitalize)
end

if __FILE__ == $0 then
    if(ARGV[0] == '-c')
        require 'coverage'
    end
    runtests testcases
end
