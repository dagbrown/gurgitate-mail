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

require 'ftools'

Modules =  %w{gurgitate/deliver.rb
             gurgitate/headers.rb 
             gurgitate/mailmessage.rb
             gurgitate/deliver/maildir.rb
             gurgitate/deliver/mbox.rb}

Targets = %w{gurgitate-mail.rb
             gurgitate-mail
             gurgitate-mail.html
             gurgitate-mail.man
             README} + Modules

Webpage=ENV["HOME"]+"/public_html/software/gurgitate-mail"
Version=File.open("VERSION").read.chomp
Tarball="gurgitate-mail-"+Version+".tar.gz"

task :default => Targets
task :dist => :tarball
task :tarball => Tarball
task :release => [:tag, :tarball, :webpage]

task(:clean) { 
    delete_all(*Targets+["pod2htm*~~","*.tmp",
        "gurgitate-mail.txt","doc","*~"]) 
}

task :install => Targets do
    require "install"
    Gurgitate::Install.install()
end

file Tarball => Targets + ["CHANGELOG","INSTALL","install.rb"] do |t|
    Dir.chdir("..") {
        puts "Creating #{Dir.pwd}/#{Tarball}..."
        files=t.prerequisites.map { |f| f.gsub(/^/,"gurgitate-mail/") }
        system("tar","zcvf",Tarball,*files)
    }
end

task :tag => "VERSION" do
    run("cvs update VERSION")
    tag="RELEASE_"+File.open("VERSION").read.chomp.gsub(/\./,"_")
    run("cvs tag #{tag}")
end

task :untag => "VERSION" do
    run("cvs update VERSION")
    tag="RELEASE_"+File.open("VERSION").read.chomp.gsub(/\./,"_")
    run("cvs tag -d #{tag}")
end

task :doc => "gurgitate-mail.rb" do |task|
    begin
        require 'rdoc/rdoc'
        RDoc::RDoc.new().document(task.prerequisites)
    end
end

task :test => :default do
    require './test'
    runtests
end

task :webpage => [Tarball,"CHANGELOG","gurgitate-mail.html"] do 
    install(Tarball,Webpage,0644)
    install("CHANGELOG",Webpage+"/CHANGELOG.txt",0644)
    install("gurgitate-mail.html",Webpage,0644)
end

# Should be ruby_"compile" but I can't put quote marks in method names :-)
def ruby_compile(task)
    task.prerequisites.each do |p|
        run("ruby -w -c #{p}")
    end
    File.copy(task.prerequisites[0], task.name, true)
end    

file("gurgitate-mail.rb" => ["gurgitate-mail.RB"]) { |t| ruby_compile(t) }
file("gurgitate-mail" => ["gurgitate.rb"]) { |t| ruby_compile(t) }
Modules.map do |modname|
    file(modname => [modname.sub(/.rb$/,".RB")]) do |t| ruby_compile(t) end
end

file "README" => "gurgitate-mail.text" do |t|
    t.source=t.prerequisites[0]
    Task[t.source].invoke
    File.copy(t.source, t.name, true)
end

%w{html text}.each do |s|
    rule('.'+s => '.pod') do |t|
        run "pod2#{s} #{t.source} > #{t.name}"
    end
end

['man'].each do |s|
    rule('.'+s => '.pod') { |t| run "pod2#{s} --center=\"Gurgitate-Mail\" #{t.source} > #{t.name}" }
end

#------------------------------------------------------------------------
# Apparently rake/contrib/sys.rb is deprecated in favor of ftools, but
# ftools doesn't have these to really handy methods, so I'm stealing 'em.
#------------------------------------------------------------------------

def run(cmd)
    puts cmd
    system(cmd) or fail "Command Failed: [#{cmd}]"
end

def delete_all(*wildcards)
    wildcards.each do |wildcard|
        Dir[wildcard].each do |fn|
            next if ! File.exist?(fn)
            if File.directory?(fn)
                Dir["#{fn}/*"].each do |subfn|
                    next if subfn=='.' || subfn=='..'
                    delete_all(subfn)
                end
                puts "Deleting directory #{fn}"
                Dir.delete(fn)
            else
                puts "Deleting file #{fn}"
                File.delete(fn)
            end
        end
    end
end

# Psst, Emacs, this file is actually -*- ruby -*-
