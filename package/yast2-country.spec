#
# spec file for package yast2-country
#
# Copyright (c) 2016 SUSE LINUX GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           yast2-country
Version:        4.0.21
Release:        0

BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Source0:        %{name}-%{version}.tar.bz2

#policy files for YaPI dbus interface
Source1:        org.opensuse.yast.modules.yapi.time.policy
Source2:        org.opensuse.yast.modules.yapi.language.policy
BuildRequires:  perl-XML-Writer
BuildRequires:  polkit-devel
BuildRequires:  update-desktop-files
BuildRequires:  yast2-devtools >= 3.1.10
BuildRequires:  yast2-perl-bindings
BuildRequires:  yast2-testsuite
# For tests
BuildRequires:  rubygem(%rb_default_ruby_abi:rspec)
BuildRequires:  rubygem(%rb_default_ruby_abi:yast-rake)
# Fix to bnc#891053 (proper reading of ".target.yast2" on chroots)
BuildRequires:  yast2-core >= 3.1.12
# RSpec extensions for YaST
BuildRequires:  yast2-ruby-bindings >= 3.1.26
# OSRelease.id
BuildRequires:  yast2 >= 3.2.9

Requires:       timezone
Requires:       yast2-perl-bindings
Requires:       yast2-trans-stats
# OSRelease.id
Requires:       yast2 >= 3.2.9
# Pkg::SetPackageLocale, Pkg::GetTextLocale
Requires:       yast2-pkg-bindings >= 2.15.3
# IconPath support for MultiSelectionBox
Requires:       yast2-core >= 2.16.28
# new API of ntp-client_proposal.ycp
Conflicts:      yast2-ntp-client < 2.18.0

Requires:       yast2-packager >= 2.23.3
# VMware detection (.probe.is_vmware)
Requires:       yast2-hardware-detection >= 3.1.6

Requires:       yast2-country-data
Requires:       yast2-ruby-bindings >= 1.0.0
Requires:       rubygem(%{rb_default_ruby_abi}:ruby-dbus)

Summary:        YaST2 - Country Settings (Language, Keyboard, and Timezone)
License:        GPL-2.0
Group:          System/YaST

%description
Country specific data and configuration modules (language, keyboard,
timezone) for yast2.

%prep
%setup -n %{name}-%{version}

%build
%yast_build

%install
%yast_install

%ifarch s390 s390x
rm -f $RPM_BUILD_ROOT%{yast_desktopdir}/keyboard.desktop
%endif

# Policies
mkdir -p $RPM_BUILD_ROOT/usr/share/polkit-1/actions
install -m 0644 %SOURCE1 $RPM_BUILD_ROOT/usr/share/polkit-1/actions/
install -m 0644 %SOURCE2 $RPM_BUILD_ROOT/usr/share/polkit-1/actions/

# common
%files
%defattr(-,root,root)
%doc %{yast_docdir}
%doc COPYING
%{yast_moduledir}/Console.rb
%{yast_moduledir}/Keyboard.rb
%{yast_moduledir}/Timezone.rb
%dir %{yast_moduledir}/YaPI
%{yast_moduledir}/YaPI/TIME.pm
%{yast_moduledir}/YaPI/LANGUAGE.pm
%{yast_clientdir}/*.rb
%dir %{yast_libdir}/y2country
%{yast_libdir}/y2country/widgets
%{yast_ydatadir}/*.ycp
%{yast_yncludedir}/keyboard/
%{yast_yncludedir}/timezone/
%{yast_scrconfdir}/*.scr
%{yast_schemadir}/autoyast/rnc/*.rnc
%{yast_desktopdir}/yast-language.desktop
%{yast_desktopdir}/timezone.desktop
%ifnarch s390 s390x
%{yast_desktopdir}/keyboard.desktop
%endif
%dir /usr/share/polkit-1
%dir /usr/share/polkit-1/actions
%attr(644,root,root) %config /usr/share/polkit-1/actions/org.opensuse.yast.modules.yapi.*.policy

%package data
Requires:       yast2-ruby-bindings >= 1.0.0

Summary:        YaST2 - Data files for Country settings
Group:          System/YaST

%description data
Data files for yast2-country together with the most often used API
functions (Language module)

%files data
%defattr(-,root,root)
%dir %{yast_ydatadir}/languages
%{yast_ydatadir}/languages/*.ycp
%{yast_moduledir}/Language.rb
%dir %{yast_libdir}/y2country
%{yast_libdir}/y2country/language_dbus.rb

%changelog
