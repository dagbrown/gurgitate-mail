#------------------------------------------------------------------------
# Rakefile for gurgitate-mail
#
# You should probably not be trying to use this if you're not me. :-) If
# you're looking at this file, that probably means you grabbed my code
# straight from CVS.  In that case, if you're feeling adventurous you
# can try "rake install".  No guarantees!  But you're really better off
# either saying "rake tarball" and using the tarball generated to
# install, or simply pulling down the latest release tarball from:
#
#       http://www.rubyforge.org/projects/gurgitate-mail/
#
# This file is read by "rake".  Don't try to run it by itself!  It'll
# just complain that it's never heard of RakeTools and then not compile.
# If you don't have rake installed then grab a copy of it at:
#
#       http://jimweirich.umlcoop.net/packages/rake/
#------------------------------------------------------------------------

include RakeTools

Targets = %w{gurgitate-mail.rb gurgitate-mail gurgitate-mail.html
             gurgitate-mail.man README}

Webpage=ENV["HOME"]+"/public_html/software/gurgitate-mail"
Version=File.open("VERSION").read.chomp
Tarball="../gurgitate-mail-"+Version+".tar.gz"

task :default => Targets
task :dist => :tarball
task :tarball => Tarball
task :release => [:tag, :tarball, :webpage]

task(:clean) { delete_all(*Targets+["pod2htm*~~","gurgitate-mail.txt","doc"]) }

task :install => Targets do
    require "install"
    Gurgitate::Install.install()
end

file Tarball => Targets + ["CHANGELOG","INSTALL","install.rb"] do |t|
    Dir.chdir("..") {
        files=t.prerequisites.map { |f| f.gsub(/^/,"gurgitate-mail/") }
        system("tar","zcvf",Tarball,*files)
    }
end

task :tag => "VERSION" do
    Sys.run("cvs update VERSION")
    tag="RELEASE_"+File.open("VERSION").read.chomp.gsub(/\./,"_")
    Sys.run("cvs tag #{tag}")
end

task :untag => "VERSION" do
    Sys.run("cvs update VERSION")
    tag="RELEASE_"+File.open("VERSION").read.chomp.gsub(/\./,"_")
    Sys.run("cvs tag -d #{tag}")
end

task :doc => "gurgitate-mail.rb" do |task|
    begin
        require 'rdoc/rdoc'
        RDoc::RDoc.new().document(task.prerequisites)
    end
end

task :webpage => [Tarball,"CHANGELOG","gurgitate-mail.html"] do 
    install(Tarball,Webpage,0644)
    install("CHANGELOG",Webpage+"/CHANGELOG.txt",0644)
    install("gurgitate-mail.html",Webpage,0644)
end

# Should be ruby_"compile" but I can't put quote marks in method names :-)
def ruby_compile(task)
    task.prerequisites.each do |p|
        Sys.run("ruby -w -c #{p}")
    end
    Sys.copy(task.prerequisites[0],task.name)
end    

file("gurgitate-mail.rb" => ["gurgitate-mail.RB"]) { |t| ruby_compile(t) }
file("gurgitate-mail" => ["gurgitate.rb"]) { |t| ruby_compile(t) }

file "README" => "gurgitate-mail.text" do |t|
    t.source=t.prerequisites[0]
    Task[t.source].invoke
    Sys.copy(t.source,t.name)
end

['html','man','text'].each do |s|
    rule('.'+s => '.pod') { |t| Sys.run "pod2#{s} #{t.source} > #{t.name}" }
end
