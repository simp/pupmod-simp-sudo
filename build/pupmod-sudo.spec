Summary: Sudo Puppet Module
Name: pupmod-sudo
Version: 4.1.0
Release: 1
License: Apache License, Version 2.0
Group: Applications/System
Source: %{name}-%{version}-%{release}.tar.gz
Buildroot: %{_tmppath}/%{name}-%{version}-%{release}-buildroot
Requires: pupmod-common >= 4.2.0-0
Requires: pupmod-concat >= 2.0.0-0
Requires: puppet >= 3.3.0
Requires: puppetlabs-stdlib >= 4.1.0-0.SIMP
Buildarch: noarch
Requires: simp-bootstrap >= 4.2.0
Obsoletes: pupmod-sudo-test

Prefix:"/etc/puppet/environments/simp/modules"

%description
This Puppet module manages the sudoers infrastructure.

%prep
%setup -q

%build

%install
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

mkdir -p %{buildroot}/%{prefix}/sudo

dirs='files lib manifests templates'
for dir in $dirs; do
  test -d $dir && cp -r $dir %{buildroot}/%{prefix}/sudo
done

mkdir -p %{buildroot}/usr/share/simp/tests/modules/sudo

%clean
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

mkdir -p %{buildroot}/%{prefix}/sudo

%files
%defattr(0640,root,puppet,0750)
/etc/puppet/environments/simp/modules/sudo

%post
#!/bin/sh

if [ -d /etc/puppet/environments/simp/modules/sudo/plugins ]; then
  /bin/mv /etc/puppet/environments/simp/modules/sudo/plugins /etc/puppet/environments/simp/modules/sudo/plugins.bak
fi

%postun
# Post uninstall stuff

%changelog
* Fri Jan 16 2015 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-1
- Changed puppet-server requirement to puppet

* Fri Apr 11 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-0
- Removed the sudo::pull_remote class.

* Wed Feb 12 2014 Kendall Moore <kmoore@keywcorp.com> - 2.1.0-0
- Updated templates to use native booleans instead of strings.

* Tue Jan 14 2014 Nick Markowski <nmarkowski@keywcorp.com> - 2.1.0-0
- Updated module for puppet3/hiera compatibility, lint tests, rspec tests.

* Mon Oct 07 2013 Kendall Moore <kmoore@keywcorp.com> - 2.0.0-9
- Updated all erb templates to properly scope variables.

* Wed Oct 02 2013 Trevor Vaughan <tvaughan@onyxpoint.com> - 2.0.0-8
- Use 'versioncmp' for all version comparisons.

* Thu Sep 12 2013 Trevor Vaughan <tvaughan@onyxpoint.com> - 2.0.7
- Updated the example documentation to note that authpriv should be
  used instead of auth so that syslog picks it up properly.

* Mon Feb 25 2013 Maintenance
2.0-6
- Added a call to $::rsync_timeout to the rsync call since it is now required.

* Thu Dec 20 2012 Maintenance
2.0.0-5
- Created a Cucumber test to add a sudo entry using the sudo module and ensure the sudoers entry is properly written.

* Thu Jun 07 2012 Maintenance
2.0.0-4
- Ensure that Arrays in templates are flattened.
- Call facts as instance variables.
- Moved mit-tests to /usr/share/simp...
- Updated pp files to better meet Puppet's recommended style guide.

* Fri Mar 02 2012 Maintenance
2.0.0-3
- Improved test stubs.

* Mon Dec 26 2011 Maintenance
2.0.0-2
- Updated the spec file to not require a separate file list.
- Scoped all of the top level variables.

* Fri Feb 11 2011 Maintenance
2.0.0-1
- Updated to use rsync native type
- Updated to use concat_build and concat_fragment types.

* Tue Jan 11 2011 Maintenance
2.0.0-0
- Refactored for SIMP-2.0.0-alpha release

* Tue Oct 26 2010 Maintenance - 1-2
- Converting all spec files to check for directories prior to copy.

* Mon Oct 04 2010 Maintenance
1.0-1
Update to ensure that any rsync modifications are not accidentally removed.

* Tue May 25 2010 Maintenance
1.0-0
- Code refactoring.

* Tue May 04 2010 Maintenance
0.2-6
- Removed strict checking and changed mode of sudoers.new
  to 440 to support the new visudo with RHEL5.5

* Wed Mar 17 2010 Maintenance
0.2-5
- Code refactor for puppet 0.25.4 de-looping.
