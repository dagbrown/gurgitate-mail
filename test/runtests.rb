require 'rubygems'
gem 'test-unit'
require 'test/unit'
require 'test/unit/ui/console/testrunner'
require 'stringio'
require 'pathname'

builddir = File.dirname(File.dirname(__FILE__))

unless $:[0] == builddir
    $:.unshift builddir
end

require "test/gurgitate-test"

def runtests(testcases)
    testcases.each do |testcase|
        Test::Unit::UI::Console::TestRunner.run testcase
    end
end

testpath = Pathname.new(__FILE__).dirname.realpath

testcases = Dir[File.join(testpath,"test_*")].map do |file|
    load file
    eval("TC_" + File.basename(file,".rb").sub(/^test_/,'').capitalize)
end

if __FILE__ == $0 then
    if(ARGV[0] == '-c')
        require 'coverage'
    end
    runtests testcases
end
