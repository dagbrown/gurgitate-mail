# $Revision: 1.1 $, $Date: 2007/12/26 07:55:11 $
Summary:	gurgitate mail filtering and mail delivery agent
Summary(pl.UTF-8):	gurgitate - narzędzie do filtrowania i dostarczania poczty
Name:		gurgitate-mail
Version:	1.8.4
Release:	1
License:	GPL
Group:		Development/Languages
Source0:	http://www.dagbrown.com/software/gurgitate-mail/%{name}-%{version}.tar.gz
# Source0-md5:	1c37cc3b319a49d6202dd21a0bd5fd86
URL:		http://www.dagbrown.com/software/gurgitate-mail/
BuildRequires:	rpmbuild(macros) >= 1.277
BuildRequires:	ruby-devel
%{?ruby_mod_ver_requires_eq}
#BuildArch:	noarch
BuildRoot:	%{tmpdir}/%{name}-%{version}-root-%(id -u -n)

%description
"gurgitate-mail" is a program which reads your mail and filters it
according to the .gurgitate-rules.rb file in your home directory. The
configuration file uses Ruby syntax and is thus quite flexible.

%description -l pl.UTF-8
gurgitate-mail to program odczytujący pocztę i filtrujący ją zgodnie z
plikiem .gurgitate-rules.rb w katalogu domowym. Plik konfiguracyjny
używa składni Ruby'ego, przez co jest dość elastyczny.

%prep
%setup -q -n %{name}

%install
rm -rf $RPM_BUILD_ROOT
install -d $RPM_BUILD_ROOT{%{_bindir},%{ruby_rubylibdir},%{_mandir}/man1}

echo "#!/usr/bin/ruby" > $RPM_BUILD_ROOT%{_bindir}/gurgitate-mail
cat gurgitate-mail >> $RPM_BUILD_ROOT%{_bindir}/gurgitate-mail
chmod +x $RPM_BUILD_ROOT%{_bindir}/gurgitate-mail
cp -a gurgitate-mail.rb $RPM_BUILD_ROOT%{ruby_rubylibdir}
cp -a gurgitate $RPM_BUILD_ROOT%{ruby_rubylibdir}
install gurgitate-mail.man $RPM_BUILD_ROOT%{_mandir}/man1/%{name}.1

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(644,root,root,755)
%attr(755,root,root) %{_bindir}/%{name}
%{ruby_rubylibdir}/*
%{_mandir}/man1/*

%define	date	%(echo `LC_ALL="C" date +"%a %b %d %Y"`)
%changelog
* %{date} PLD Team <feedback@pld-linux.org>
All persons listed below can be reached at <cvs_login>@pld-linux.org

$Log: gurgitate-mail.spec,v $
Revision 1.1  2007/12/26 07:55:11  aredridel
- added spec, from PLD sources

Revision 1.10  2007/03/29 18:39:50  aredridel
- 1.8.2

Revision 1.9  2007/03/12 04:05:40  aredridel
- 1.8.1

Revision 1.8  2007/02/13 07:47:11  glen
- tabs in preamble

Revision 1.7  2007/02/12 00:48:55  baggins
- converted to UTF-8

Revision 1.6  2006/10/28 20:28:53  aredridel
- 1.6.3

Revision 1.5  2006/03/21 07:17:29  aredridel
- up to 1.6.2

Revision 1.4  2006/02/17 04:57:56  aredridel
- up to 1.6.0

Revision 1.3  2006/02/16 00:21:42  aredridel
- up to 1.6.0preview5

Revision 1.2  2006/02/01 09:00:02  qboosh
- pl, cleanups

Revision 1.1  2006/02/01 08:46:27  aredridel
- added
