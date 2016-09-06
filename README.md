[![License](http://img.shields.io/:license-apache-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0.html) [![Build Status](https://travis-ci.org/simp/pupmod-simp-sudo.svg)](https://travis-ci.org/simp/pupmod-simp-sudo) [![SIMP compatibility](https://img.shields.io/badge/SIMP%20compatibility-4.2.*%2F5.1.*-orange.svg)](https://img.shields.io/badge/SIMP%20compatibility-4.2.*%2F5.1.*-orange.svg)

# sudo

#### Table of Contents

1. [Module Description - What the module does and why it is useful](#module-description)
2. [Setup - The basics of getting started with sudo](#setup)
    * [What sudo affects](#what-sudo-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with sudo](#beginning-with-sudo)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference]
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
sudo::user_specification { 'power_users':
  user_list => 'persona, personb, %powerusers',
  runas     => 'root',
  cmnd      => [ '/bin/su root', '/bin/su - root' ]
}
```

Giving a system user access to a command without root

```puppet
sudo::user_specification { 'myapp':
  user_list => 'myappuser',
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

* sudo: Handles main /etc/sudoers file

### Defined Types

* sudo::default_entry: Creates default entry
* sudo::user_specification: Creates user entry
* sudo::alias: Creates Aliases (Used by all other sudo::alias types)
* sudo::alias::cmnd: Creates Command Aliases
* sudo::alias::host: Creates Host Aliases
* sudo::alias::runas: Creates Run As Aliases
* sudo::alias::user: Creates User Aliases

### Class: `sudo`
Main class, builds /etc/sudoers file

No Parameters

### Type: `sudo::default_entry`

#### Parameters

Adds an entry to the defaults section of /etc/sudoers in order to override
runtime defaults. See the 'Defaults' section of sudoers(5) for more
information.

* `content`: The content of the sudoers default entry. Valid options: String.
* `target` (Optional): User, host or other object that is the target of the
content. Valid options: String. Default: None
* `def_type` (Optional): Type of Entry. Valid options: 'base', 'host', 'user',
or 'runas'. Default: base.

### Type: `sudo::user_specification`

Add a user_spec entry to /etc/sudoers in order to determine which commands
a user may run as the given user on the given host.
See the 'User Specification' section of sudoers(5) for more information.
Note that the 'Tag_Spec' entries have been explicitly noted below.

#### Parameters

* `user_list`: Array of users or groups that should be able to execute a
command. Groups must be preceded by %. Valid options: String.

* `cmnd`: Commands you wan to run. Valid options: Array

* `host_list` (Optional): Array of hosts where the specified users should be
able to execute a command. Valid options: hostname. Default: `$::hostname`

* `runas` (Optional): Can be an array of users that you need to be able to run the
commands as. It will probably just be one user in most cases. Type: Array.
Default: 'root'

* `passwd` (Optional): Whether or not to require a password for sudo. Valid
options: Boolean. Default: true

* `doexec` (Optional): Set EXEC in /etc/sudoers. Valid options: Boolean.
Default: true

* `setenv` (Optional): Set SETENV in /etc/sudoers. Valid options: Boolean.
Default: true

### Type: `sudo::alias`

Adds an alias to /etc/sudoers.
See the 'Aliases' section of sudoers (5) for information about aliases

#### Parameters

* `content`: The comma-separated array of items that will be the content of
this alias, For example: 'administrators', 'wheel'. Valid options: Array.

* `alias_type`:
The type of alias to create. Valid options: 'user', 'runas', 'host' or 'cmnd'.

* `comment` (Optional): Textual comment for this entry. Valid options: string.
Default: None.

* `order` (Optional): If desired, force the order of this entry relative to
other entries. Usually not required. Valid options: Integer. Default: 10.

### Types:
### `sudo::alias::cmnd`
### `sudo::alias::host`
### `sudo::alias::runas`
### `sudo::alias::user`

Calls the sudo::alias defined type with the alias_type of cmnd, host, runas
or user respectively. Just an easy to read way to call sudo::alias.

#### Parameters

* `content`: The comma-separated array of items that will be the content of
this alias, For example: 'administrators', 'wheel'. Valid options: Array.

* `comment` (Optional): Textual comment for this entry. Valid options: string.
Default: None.

* `order` (Optional): If desired, force the order of this entry relative to
other entries. Usually not required. Valid options: Integer. Default: 10.

## Limitations

SIMP Puppet modules are generally intended to be used on a Red Hat Enterprise
Linux-compatible distribution.

## Development

Please read our [Contribution Guide](https://simp-project.atlassian.net/wiki/display/SD/Contributing+to+SIMP)
and visit our [Developer Wiki](https://simp-project.atlassian.net/wiki/display/SD/SIMP+Development+Home)

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
