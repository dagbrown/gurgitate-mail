require 'rubygems'

spec = Gem::Specification.new do |s|

    # Basic information.
    s.name = 'gurgitate-mail'
    s.version = File.open("VERSION").read.strip
    s.summary = <<-EOF
    gurgitate-mail is a mail filter (and a mail-delivery agent)
    EOF
    s.description = <<-EOF
    gurgitate-mail is a mail filter.  It can be used as a module or
    as a standalone application.
    EOF
    s.author = "Dave Brown"
    s.email = "gurgitate-mail@dagbrown.com"
    s.homepage = "http://www.github.com/dagbrown/gurgitate-mail/"

    s.files = Dir.glob("lib/**/*.rb").delete_if { |item| item.include?"CVS" }
    s.files += Dir.glob("test/**/*.rb").delete_if { |item| item.include? "CVS" }
    s.files += [ '.gemtest', 'Rakefile' ]
    # Load-time details: library and application
    s.require_path = 'lib'                 # Use these for libraries.

    s.bindir = "bin"                       # Use these for applications.
    s.executables = ["gurgitate-mail"]
    s.default_executable = "gurgitate-mail"
    s.license = 'GPL-2.0'

    # Documentation and testing.
    s.has_rdoc = true
    s.test_files = Dir["test/*.rb"]
end
