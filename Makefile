TARGETS = gurgitate-mail.rb gurgitate-mail gurgitate-mail.html gurgitate-mail.man README 

TARBALL=$(shell echo gurgitate-mail-`cat VERSION`.tar.gz)
WEBPAGE=$(HOME)/public_html/software/gurgitate-mail

all: $(TARGETS)

dist: tarball

clean:
	-rm -f $(TARGETS) 
	-rm -f pod2htm*~~

tarball: $(TARGETS) INSTALL CHANGELOG
	cd .. && tar zcvf $(TARBALL) \
        gurgitate-mail/INSTALL \
        gurgitate-mail/install.rb \
        gurgitate-mail/gurgitate-mail \
        gurgitate-mail/gurgitate-mail.rb \
        gurgitate-mail/gurgitate-mail.html \
        gurgitate-mail/gurgitate-mail.man \
        gurgitate-mail/CHANGELOG \
        gurgitate-mail/README

gurgitate-mail.rb: gurgitate-mail.RB
	ruby -w -c $< && cp $< $@

gurgitate-mail: gurgitate.rb
	ruby -w -c $< && cp $< $@
	chmod +x gurgitate-mail

gurgitate-mail.html: gurgitate-mail.pod
	pod2html $< > $@

gurgitate-mail.man: gurgitate-mail.pod
	pod2man $< > $@

README: gurgitate-mail.pod
	pod2text $< > $@

tag: VERSION
	cvs update VERSION
	@echo "Adding tag RELEASE_"`sed 's/\./_/g' VERSION`
	cvs tag RELEASE_`sed 's/\./_/g' VERSION` .

untag: VERSION
	cvs update VERSION
	@echo "Removing tag RELEASE_"`sed 's/\./_/g' VERSION`
	cvs tag -d RELEASE_`sed 's/\./_/g' VERSION` .

release: tag tarball
	cp ../$(TARBALL) $(WEBPAGE)
	chmod 644 $(WEBPAGE)/$(TARBALL)
	cp CHANGELOG $(WEBPAGE)/CHANGELOG.txt
	chmod 644 $(WEBPAGE)/CHANGELOG.txt
	cp gurgitate-mail.html $(WEBPAGE)
	chmod 644 $(WEBPAGE)/gurgitate-mail.html
