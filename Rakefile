#========================================================================
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
#========================================================================

require 'fileutils'
require 'rubygems'

BuildDir = "BUILD"

Package = "gurgitate-mail"

Modules =  %w{gurgitate/deliver.rb
             gurgitate/headers.rb 
             gurgitate/mail_headers.rb
             gurgitate/message.rb
             gurgitate/header.rb 
             gurgitate/mailmessage.rb
             gurgitate/deliver/maildir.rb
             gurgitate/deliver/mbox.rb
             gurgitate/deliver/mh.rb}

Targets = %w{gurgitate-mail.rb
             gurgitate-mail
             gurgitate-mail.html
             gurgitate-mail.man
             README} + Modules

Tests = Dir["test/test_*.rb"]

Gemspec = "#{Package}.gemspec"

Releasefiles = %w{CHANGELOG INSTALL install.rb} + Targets + Tests

Webpage=ENV["HOME"]+"/public_html/software/gurgitate-mail"
Version=File.open("VERSION").read.chomp
Tarball="gurgitate-mail-"+Version+".tar.gz"
Gemfile="gurgitate-mail-"+Version+".gem"

task :default => Targets
task :dist => [ :tarball, :gem ]
task :tarball => Tarball
task :release => [:tag, :dist, :webpage]
task :rerelease => [:untag, :tag, :tarball, :webpage]

task :gem => Gemfile

task :clean => :gem_cleanup do
    delete_all(*Targets+["pod2htm*~~","*.tmp",
        "gurgitate-mail.text","doc","*~"]) 
end

task :gem_cleanup do
    delete_all BuildDir
    delete_all "*.gem"
end

file Gemfile => [ Gemspec, :gem_install ] do
    gemspec = eval File.read(Gemspec)
    FileUtils.touch File.join(BuildDir, ".gemtest")
    olddir = Dir.pwd
    chdir BuildDir
    system("gem","build",File.join("..",Gemspec))
    FileUtils.mv Gemfile,olddir
    chdir olddir
end

task :gem_install => Targets do
    load "install.rb"
    Gurgitate::Install.install BuildDir
end

task :install => Targets do
    load "install.rb"
    Gurgitate::Install.install
end

file Tarball => Releasefiles do |t|
    Dir.chdir("..") do
        puts "Creating #{Dir.pwd}/#{Tarball}..."
        files=t.prerequisites.map { |f| f.gsub(/^/,"gurgitate-mail/") }
        File.chmod(0644, *files)
        system("tar","zcvf",Tarball,*files)
    end
end

task :tag => "VERSION" do
    run("git checkout -f VERSION")
    tag="RELEASE_"+File.open("VERSION").read.chomp.gsub(/\./,"_")
    run("git tag #{tag}")
end

task :untag => "VERSION" do
    run("git checkout -f VERSION")
    tag="RELEASE_"+File.open("VERSION").read.chomp.gsub(/\./,"_")
    run("git tag -d #{tag}")
end

task :doc => "gurgitate-mail.rb" do |task|
    begin
        require 'rdoc/rdoc'
        RDoc::RDoc.new().document(task.prerequisites)
    end
end

task :test => :default do
    $:.unshift File.dirname(__FILE__)
    require './test/runtests'

    testcases = Tests.map do |file|
        load file
        eval("TC_" + File.basename(file,".rb").sub(/^test_/,'').capitalize)
    end

    runtests testcases
end

task :cover => :default do
    system("rcov #{BuildDir}/test/runtests.rb")
end

task :webpage => [Tarball,"CHANGELOG","gurgitate-mail.html"] do 
    FileUtils.install(File.join("..",Tarball),Webpage,:mode => 0644)
    FileUtils.install(Gemfile, Webpage, :mode => 0644)
    FileUtils.install("CHANGELOG",Webpage+"/CHANGELOG.txt", :mode => 0644)
    FileUtils.install("gurgitate-mail.html",Webpage, :mode => 0644)
end

# Should be ruby_"compile" but I can't put quote marks in method names :-)
def ruby_compile(task)
    task.prerequisites.each do |p|
        run("ruby -w -c #{p}")
    end
    FileUtils.cp(task.prerequisites[0], task.name)
end    

file("gurgitate-mail.rb" => ["gurgitate-mail.RB"]) { |t| ruby_compile(t) }
file("gurgitate-mail" => ["gurgitate.rb"]) { |t| ruby_compile(t) }
Modules.map do |modname|
    file(modname => [modname.sub(/.rb$/,".RB")]) do |t| ruby_compile(t) end
end

file "README" => "gurgitate-mail.text" do |t|
    t.sources=[t.prerequisites[0]]
    FileUtils.cp(t.source, t.name)
end

%w{html text}.each do |s|
    rule('.'+s => '.pod') do |t|
        run "pod2#{s} #{t.source} > #{t.name}"
    end
end

['man'].each do |s|
    rule('.'+s => '.pod') do |t| 
        run "pod2#{s} --center=\"Gurgitate-Mail\" #{t.source} > #{t.name}" 
    end
end

#------------------------------------------------------------------------
# Apparently rake/contrib/sys.rb is deprecated in favor of ftools, but
# ftools doesn't have these two really handy methods, so I'm stealing 'em.
#------------------------------------------------------------------------

def run(cmd)
    puts cmd
    system(cmd) or fail "Command Failed: [#{cmd}]"
end

def delete_all(*wildcards)
    wildcards.each do |wildcard|
        FileUtils.rm_rf wildcard
    end
end

# Psst, Emacs, this file is actually -*- ruby -*-
