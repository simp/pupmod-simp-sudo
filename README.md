[![License](https://img.shields.io/:license-apache-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0.html)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/73/badge)](https://bestpractices.coreinfrastructure.org/projects/73)
[![Puppet Forge](https://img.shields.io/puppetforge/v/simp/sudo.svg)](https://forge.puppetlabs.com/simp/sudo)
[![Puppet Forge Downloads](https://img.shields.io/puppetforge/dt/simp/sudo.svg)](https://forge.puppetlabs.com/simp/sudo)
[![Build Status](https://travis-ci.org/simp/pupmod-simp-sudo.svg)](https://travis-ci.org/simp/pupmod-simp-sudo)

# sudo

#### Table of Contents

1. [Module Description - What the module does and why it is useful](#module-description)
2. [Setup - The basics of getting started with sudo](#setup)
    * [What sudo affects](#what-sudo-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with sudo](#beginning-with-sudo)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)
7. [Acceptance Tests](#acceptance-tests)

## Module Description

Constructs a sudoers file based on configuration aliases, defaults, and user
specifications.

## Setup

### What sudo affects

sudo will ensure the sudo package is installed, and will manage /etc/sudoers.

### Setup Requirements

The only necessary steps to begin using sudo is the install `pupmod-simp-sudo`
into your modulepath

### Beginning with sudo

To create the default SIMP /etc/sudoers file:

```puppet
include 'sudo'
```

## Usage

### Add a user to sudoers

Giving a user root permissions

```puppet
# NOTE: '%' in sudo signifies a group
# %powerusers is the powerusers group

sudo::user_specification { 'power_users':
  user_list => [ 'persona', 'personb', '%powerusers' ],
  runas     => 'root',
  cmnd      => [ '/bin/su root', '/bin/su - root' ]
}
```

Giving a system user access to a command without root

```puppet
sudo::user_specification { 'myapp':
  user_list => [ 'myappuser' ],
  runas     => 'root',
  cmnd      => [ '/usr/bin/someservice' ],
  passwd    => false,
}
```

### Create a sudo default entry

To create a defaults line in sudoers:



```puppet

# Creates Defaults   requiretty, syslog=authpriv, !root_sudo, !umask, env_reset

sudo::default_entry { '00_main':
  content => [ 'requiretty',
               'syslog=authpriv',
               '!root_sudo',
               '!umask',
               'env_reset',
             ],
}
```

### Create an alias

To create the following alias in sudoers:
`User_Alias FULLTIMERS = millert, mikef, dowdy`

```puppet
sudo::alias { 'FULLTIMERS':
  content => [ 'millert','mikef','dowdy' ],
  alias_type => 'user'
}
```

Additionally, these may be called by additional defined types for user, cmnd,
host, or runas for easier readibility:

```puppet
sudo::alias::user { 'FULLTIMERS':
  content => [ 'millert','mikef','dowdy' ],
}
```

## Reference

### Classes

#### Public Classes

* [sudo](https://github.com/simp/pupmod-simp-sudo/blob/master/manifests/init.pp): Handles main /etc/sudoers file

### Defined Types

* [sudo::default_entry](https://github.com/simp/pupmod-simp-sudo/blob/master/manifests/default_entry.pp): Creates default entry
* [sudo::user_specification](https://github.com/simp/pupmod-simp-sudo/blob/master/manifests/user_specification.pp): Creates user entry
* [sudo::alias](https://github.com/simp/pupmod-simp-sudo/blob/master/manifests/alias.pp): Creates Aliases (Used by all other sudo::alias types)
* [sudo::alias::cmnd](https://github.com/simp/pupmod-simp-sudo/blob/master/manifests/alias/cmnd.pp): Creates Command Aliases
* [sudo::alias::host](https://github.com/simp/pupmod-simp-sudo/blob/master/manifests/alias/host.pp): Creates Host Aliases
* [sudo::alias::runas](https://github.com/simp/pupmod-simp-sudo/blob/master/manifests/alias/runas.pp): Creates Run As Aliases
* [sudo::alias::user](https://github.com/simp/pupmod-simp-sudo/blob/master/manifests/alias/user.pp): Creates User Aliases

## Limitations

SIMP Puppet modules are generally intended to be used on a Red Hat Enterprise
Linux-compatible distribution.

## Development

Please read our [Contribution Guide](https://simp.readthedocs.io/en/stable/contributors_guide/index.html).

If you find any issues, they can be submitted to our
[JIRA](https://simp-project.atlassian.net).

## Acceptance tests

To run the system tests, you need `Vagrant` installed.

You can then run the following to execute the acceptance tests:

```shell
   bundle exec rake beaker:suites
```

Some environment variables may be useful:

```shell
   BEAKER_debug=true
   BEAKER_provision=no
   BEAKER_destroy=no
   BEAKER_use_fixtures_dir_for_modules=yes
```

*  ``BEAKER_debug``: show the commands being run on the STU and their output.
*  ``BEAKER_destroy=no``: prevent the machine destruction after the tests
   finish so you can inspect the state.
*  ``BEAKER_provision=no``: prevent the machine from being recreated.  This can
   save a lot of time while you're writing the tests.
*  ``BEAKER_use_fixtures_dir_for_modules=yes``: cause all module dependencies
   to be loaded from the ``spec/fixtures/modules`` directory, based on the
   contents of ``.fixtures.yml``. The contents of this directory are usually
   populated by ``bundle exec rake spec_prep``. This can be used to run
   acceptance tests to run on isolated networks.
