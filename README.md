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

Manages sudo configuration through aliases, defaults, and user
specifications, written as individual drop-in files under `/etc/sudoers.d/`.

## Breaking changes in 7.0.0

Version 7.0.0 reduces the "blast radius" of this module. **A bare
`include sudo` now installs the `sudo` package and does nothing else.** In
particular:

- The module **no longer takes ownership of `/etc/sudoers`**. Previously a
  bare `include sudo` declared a `concat` resource for `/etc/sudoers`,
  which took whole-file ownership of that shared file and, with no entries
  configured, *blanked* it (wiping the OS-shipped `Defaults` and
  `#includedir`). A bare `include sudo` now leaves `/etc/sudoers`
  completely untouched. When the module manages at least one entry, the
  only writes it ever makes to `/etc/sudoers` are the two minimal,
  line-targeted upgrade aids described under
  [Upgrading from 6.x](#upgrading-from-6x) (both can be disabled).
- All managed entries (`sudo::alias`, `sudo::default_entry`,
  `sudo::user_specification`, and the `#includedir` lines from
  `sudo::include_dir`) are now written as **individual files under
  `/etc/sudoers.d/`** (configurable via the `sudo::content_dir` parameter),
  which sudo reads via its default `#includedir`. File names carry a
  numeric prefix so the previous relative ordering (aliases, then defaults,
  then user specifications) is preserved. Titles containing characters
  outside `[0-9A-Za-z_-]` are sanitized (sudo skips include-dir files with
  a `.` in the name) and receive a short digest suffix so distinct titles
  can never collide into one file. Note that sanitization can change how
  two same-prefix entries sort relative to each other compared to 6.x's
  fragment ordering — sudoers is last-match-wins, so if the relative order
  of two entries matters, prefer titles that need no sanitization.
- The **`puppetlabs/concat` dependency has been removed.** Validation is
  now performed with `visudo` directly, in two layers:
  - Each drop-in file is validated with a non-strict `visudo -cf` *before*
    it is installed (`sudo::validate`, or the per-resource `validate`
    parameter; default `true`). Non-strict validation rejects genuine
    syntax errors and unknown Defaults options but tolerates references to
    aliases defined in other files (they only produce warnings), so
    entries may still be split across multiple files.
  - Whenever a managed file changes, the complete assembled configuration
    is checked with a strict `visudo -csf /etc/sudoers`
    (`sudo::strict_config_check`; default `true`). This is a parse-only
    check — visudo's owner/mode checks are skipped so that pre-existing
    unmanaged drop-ins with lax permissions do not fail the run. It runs
    after the write, so it cannot prevent an
    invalid cross-file configuration from landing, but it fails the Puppet
    run so problems like a dangling alias reference are surfaced
    immediately.
- `sudo::package_ensure` no longer follows `simp_options::package_ensure`;
  it defaults to `installed`.
- **Removing an entry from your manifests/Hiera no longer removes the
  rule.** This module is deliberately non-destructive: it never purges the
  content directory, so a drop-in file whose Puppet resource goes away is
  simply left in place and sudo keeps honoring it. (Under 6.x, deleting an
  entry removed its `concat` fragment and the rule disappeared on the next
  run.) To revoke an entry, keep the resource and set `ensure => absent`
  on it — every define (`sudo::alias`, `sudo::alias::*`,
  `sudo::default_entry`, `sudo::user_specification`,
  `sudo::include_dir`) supports it:

  ```yaml
  sudo::user_specifications:
    contractor_su:
      user_list: ['contractor']
      cmnd: ['/bin/su']
      ensure: absent
  ```

  This is the standard lifecycle pattern for drop-in-directory Puppet
  modules; it trades automatic reaping for the guarantee that this module
  never deletes a file it cannot prove it owns.
- **Declaring `sudo::include_dir` for the content directory itself writes
  nothing.** A drop-in *inside* `/etc/sudoers.d` that re-includes
  `/etc/sudoers.d` would make sudo fail with `too many levels of includes`
  (a complete sudo lockout), so when `$include_dir` equals
  `sudo::content_dir` the drop-in is skipped — `sudo::manage_includedir`
  already guarantees `/etc/sudoers` reads the content directory. Sites
  carrying `sudo::include_dirs: ['/etc/sudoers.d']` in Hiera (the way 6.x
  enabled drop-ins) can keep it; it is now a safe no-op.

### Recovery paths

1. **Per parameter:** set the parameters you need explicitly (the defines
   work exactly as before — they simply write to `/etc/sudoers.d/` now).
2. **`simp:defaults` profile:** enable the shipped compliance_engine
   profile to restore the pre-refactor defaults stack-wide:

   ```yaml
   compliance_engine::enforcement:
     - simp:defaults
   ```

   For sudo this restores `sudo::package_ensure: installed`. A value set
   explicitly in your own Hiera always wins over the profile.

   > **Note:** the profile restores parameter *values* only. The former
   > whole-file management of `/etc/sudoers` was structurally removed (there
   > is no parameter for it) and is intentionally **not** restorable.

### Upgrading from 6.x

Version 6.x owned `/etc/sudoers` outright, so a system upgraded to 7.0.0
starts out with a stale, module-generated `/etc/sudoers` that this version
will never rewrite. Left alone, that file causes two problems: if it lacks
an `#includedir` directive for `/etc/sudoers.d` (6.x only wrote one when
`sudo::include_dirs` was set), the new drop-in files are **silently
ignored** by sudo; and where it does contain the old entries, they
duplicate the drop-in content — a duplicate alias definition is a sudoers
parse error. Two line-targeted mechanisms, both enabled by default, handle
this:

- **`sudo::manage_includedir`** (default `true`) — whenever this module
  manages at least one entry, it ensures `/etc/sudoers` contains an
  `#includedir` directive for `sudo::content_dir`. The line is appended
  with `file_line` **only if** no equivalent `#includedir`/`@includedir`
  directive is already present; an existing directive is never modified.
  If you disable this, you are responsible for ensuring the directive
  exists by other means — the module logs a warning whenever entries are
  managed with this disabled, because without the directive they are
  inert.
- **`sudo::remove_legacy_entries`** (default `true`) — removes lines from
  `/etc/sudoers` that are **byte-identical** to entry content this module
  now writes as drop-in files (6.x wrote the same template output directly
  into `/etc/sudoers`). The match is on content, not provenance, but that
  is what makes it safe: a line is only ever removed while the module is
  simultaneously enforcing that exact content as a drop-in, so the
  effective sudo policy cannot change — regardless of whether the line was
  written by 6.x, by an administrator, or shipped by the OS. `#includedir`
  lines are deliberately excluded from cleanup, since the 6.x-written one
  may be the directive keeping the drop-ins active. This is an upgrade
  aid, not a permanent feature: it is slated for removal in the next major
  release, after which any remaining 6.x remnants must be cleaned up by
  hand (or by re-enabling it explicitly while it still exists).

Both mechanisms activate only when the module actually manages entries — a
bare `include sudo` still touches nothing. Note that the OS-shipped
`/etc/sudoers` content that 6.x wiped (`Defaults` such as `secure_path`,
`env_reset`, and `requiretty`) is **not** restored; recover it from
`/etc/sudoers.rpmnew` or the `sudo` package if your site needs it.

### What sudo affects

sudo ensures the `sudo` package is installed and, when entries are
configured, writes them as drop-in files under `/etc/sudoers.d/`.

### Setup Requirements

The only necessary steps to begin using sudo is the install `pupmod-simp-sudo`
into your modulepath

### Beginning with sudo

A bare include installs the package only:

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
