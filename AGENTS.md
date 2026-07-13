# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## What this module does

`simp-sudo` is a SIMP Puppet module that manages the system `sudo`
configuration. It installs the `sudo` package and composes a single
`/etc/sudoers` file from discrete, individually-declared fragments using
`puppetlabs/concat`, validating the result with `visudo` before it is written
(`manifests/init.pp`).

The module does not manage one monolithic template. Instead it exposes a set of
building blocks — user specifications, aliases, `Defaults` entries, and
`#includedir` lines — each of which contributes one `concat::fragment` to
`/etc/sudoers`. The `sudo` class can drive all of them from Hiera-supplied
hashes, or you can declare the defined types directly.

### Business logic

The single class is `sudo` (`manifests/init.pp`); everything else is a
defined type. None of the manifests are `assert_private()`'d, and every defined
type does `include 'sudo'` (e.g. `user_specification.pp`,
`include_dir.pp`), so declaring any fragment pulls in the base class, the
`sudo` package, and the `/etc/sudoers` concat automatically.

- **`sudo` (`manifests/init.pp`)** — entry class. Parameters
  (`init.pp`): `$user_specifications`, `$default_entries`, `$aliases`
  (all `Hash`, default `{}`), `$package_ensure` (`String`), and `$include_dirs`
  (`Array[Stdlib::Absolutepath]`, default `[]`). It declares
  `package { 'sudo' }`, the `concat { '/etc/sudoers' }` target (mode `0440`,
  `validate_cmd => '/usr/sbin/visudo -q -c -f %'`), then iterates each hash and
  fans it out to the matching defined type via the splat (`*`) operator
  (`init.pp`). Hiera hashes are deep-merged (`hiera.yaml` /
  `data/common.yaml` `lookup_options`).

- **`sudo::user_specification` (`manifests/user_specification.pp`)** — one
  sudoers user-spec line (`user host=(runas) TAGS: cmnd`). Renders
  `templates/uspec.epp` into a fragment at `order => 90`. `$host_list` defaults
  to the node's own hostname + FQDN (`user_specification.pp`); `$runas`
  defaults to `['root']`.

- **`sudo::alias` (`manifests/alias.pp`)** — a single alias entry
  (`User_Alias`/`Host_Alias`/`Runas_Alias`/`Cmnd_Alias`). Takes an
  `$alias_type` of type `Sudo::AliasType` and renders `templates/alias.epp`
  into a fragment whose default `order` is `10`.

- **`sudo::alias::cmnd` / `::host` / `::runas` / `::user`
  (`manifests/alias/*.pp`)** — thin convenience wrappers that call
  `sudo::alias` with a fixed `alias_type` and a type-specific default `order`
  (cmnd `10`, host `12`, runas `14`, user `16`). See `alias/cmnd.pp`.

- **`sudo::default_entry` (`manifests/default_entry.pp`)** — one
  `Defaults` line. `$def_type` (`Sudo::DefType`, default `'base'`) selects the
  `Defaults` binding symbol (`@`/`:`/`>`/`!` or none) in `templates/defaults.epp`.
  Fragment `order => 80`.

- **`sudo::include_dir` (`manifests/include_dir.pp`)** — manages an
  `#includedir` directory as a `file` resource and appends an
  `#includedir <path>` line as a fragment at `order => 1000` (last), so drop-in
  files are sourced after everything the module wrote inline. `$tidy_include_dir`
  (default `false`) controls `purge`/`recurse` of that directory.

**Fragment ordering** determines the layout of the generated `/etc/sudoers`:
aliases (10-16) → `Defaults` (80) → user specs (90) → `#includedir` (1000).

### The CVE-2019-14287 mitigation seam

This is the module's most non-obvious behavior. For `sudo` versions **before
1.8.28**, a `runas` list of `ALL` / `%ALL` could be abused (a `-1` uid/gid maps
to root and can bypass a `!root` restriction and skip auditing). The module
guards against this:

- The `sudo_version` fact (`lib/facter/sudo_version.rb`) resolves the installed
  sudo version by running `sudo -V`.
- The `sudo::update_runas_list` function
  (`lib/puppet/functions/sudo/update_runas_list.rb`) appends `!#-1` when `ALL`
  is present and `!%#-1` when `%ALL` is present, de-duplicated
  (`update_runas_list.rb`). It has two dispatches — one for `Array`, one
  for a single `String`.
- Three call sites apply it **only** for runas content **and only** when the
  fact is absent or the version is `< 1.8.28`
  (`versioncmp(..., '1.8.28') >= 0` short-circuits it):
  `user_specification.pp`, `alias.pp` (only when
  `$alias_type == 'runas'`), and `default_entry.pp` (only when
  `$def_type == 'runas'`). On current sudo (EL8+ ships ≥ 1.8.28) the content
  passes through unchanged.

### Gotchas / non-obvious details

- **Every defined type `include`s the base `sudo` class.** You never need to
  declare `sudo` explicitly before using a fragment type — but it also means a
  fragment cannot be declared in isolation from the class's package/concat
  resources.
- **`user_specification` targets the local node by default.** `$host_list`
  defaults to `[hostname, fqdn]` (`user_specification.pp`), not `ALL`. If you
  want a spec to apply everywhere, pass `host_list => ['ALL']` explicitly.
- **`SETENV`/`NOSETENV` is only emitted on RedHat-family hosts.** `uspec.epp`
  gates the setenv tag on `$facts['os']['family'] == 'RedHat'`
  (`templates/uspec.epp`); on other families the `$setenv` parameter has
  no effect on output.
- **The CVE mitigation is version- and type-conditional** (see the seam above).
  It fires only for `runas`-flavored content on old sudo; do not "simplify" it
  by applying `update_runas_list` unconditionally.
- **`include_dir` fragments sort last (`order => 1000`).** Anything managed via
  an included drop-in directory is evaluated after the inline entries.
- **`.epp`, not `.erb`.** All three templates are embedded *Puppet* templates
  (`templates/*.epp`), rendered with `epp()` and typed parameter blocks — not
  Ruby ERB. Edit them as Puppet, not Ruby.
- **`simplib::lookup` is the only `simp_options` seam.** The sole SIMP option
  consumed is `simp_options::package_ensure` at `init.pp` (default
  `'installed'`). There is no `simp_options::sudo`-style master switch.
- **`simp/simp_options` is NOT a declared dependency** in `metadata.json`, yet
  `init.pp` reads the `simp_options::*` seam via `simplib::lookup` (provided
  by `simp/simplib`). Keep routing feature toggles through `simplib::lookup`
  with an explicit `default_value` rather than assuming `simp_options` is
  included.

## Dependencies

Module dependencies (from `metadata.json`):

- `puppetlabs/concat` `>= 6.4.0 < 10.0.0` — provides `concat` /
  `concat::fragment`, the core mechanism this module uses to assemble
  `/etc/sudoers`.
- `puppetlabs/stdlib` `>= 8.0.0 < 10.0.0` — provides `Stdlib::Absolutepath`.
- `simp/simplib` `>= 4.9.0 < 6.0.0` — provides `simplib::lookup` and the
  `Simplib::Hostname` type used by `user_specification`.

There are **no optional dependencies** — `metadata.json` has no
`simp.optional_dependencies` block, and no manifest calls
`simplib::assert_optional_dependency`.

Runtime requirement (from `metadata.json` `requirements`): `openvox
>= 8.0.0 < 9.0.0`. This module has migrated its runtime baseline from Puppet to
**OpenVox**. The `Gemfile` reflects the transition: the default test version is
`['>= 8', '< 9']` (`Gemfile`) and it installs **both** the `openvox` and
`puppet` gems in a loop — `['openvox', 'puppet'].each do |gem_name|`
(`Gemfile`). This "both gems" install is a temporary shim kept only until
the `puppet` gem dependency is removed from the other gems in the stack (see the
comment at `Gemfile`); OpenVox is a drop-in Puppet fork, so the two coexist.

Supported OS matrix (from `metadata.json`): CentOS 9/10; RedHat 8/9/10;
OracleLinux 8/9/10; Rocky 8/9/10; AlmaLinux 8/9/10.

## Repository layout

- `manifests/init.pp` — the `sudo` class (package, `/etc/sudoers` concat, and
  the Hiera-driven fan-out to the defined types).
- `manifests/user_specification.pp` — `sudo::user_specification` defined type.
- `manifests/default_entry.pp` — `sudo::default_entry` defined type.
- `manifests/include_dir.pp` — `sudo::include_dir` defined type.
- `manifests/alias.pp` — `sudo::alias` (the generic alias type).
- `manifests/alias/{cmnd,host,runas,user}.pp` — convenience wrappers around
  `sudo::alias`.
- `types/aliastype.pp` — `Sudo::AliasType` = `Enum['user','runas','host','cmnd']`.
- `types/deftype.pp` — `Sudo::DefType` =
  `Enum['base','cmnd','host','user','runas']`.
- `lib/facter/sudo_version.rb` — the `sudo_version` custom fact (runs `sudo -V`).
- `lib/puppet/functions/sudo/update_runas_list.rb` — the
  `sudo::update_runas_list` function (CVE-2019-14287 mitigation).
- `templates/uspec.epp`, `templates/alias.epp`, `templates/defaults.epp` —
  embedded **Puppet** templates for the three rendered fragment kinds.
- `data/common.yaml` — module data; here it holds only the deep-merge
  `lookup_options` for the three Hiera-driven hashes.
- `hiera.yaml` — module data hierarchy (v5): a single `common.yaml` layer.
- `metadata.json` — dependencies, OS matrix, and the OpenVox runtime
  requirement.
- `spec/classes/`, `spec/defines/` — rspec-puppet unit tests.
- `spec/acceptance/suites/default/00_default_spec.rb` — the single beaker
  acceptance suite; nodesets under `spec/acceptance/nodesets/` (15 of them).
- `REFERENCE.md` — generated Puppet Strings reference.

### CI

`.github/workflows/pr_tests.yml` runs on pull requests. Six standard jobs —
`puppet-syntax`, `puppet-style` (lint + `metadata_lint`), `ruby-style`
(rubocop, `continue-on-error`), `file-checks`, `releng-checks` (version/tag
checks + a test `pdk build`), and `spec-tests` (`parallel_spec` on Puppet 8.x) —
plus an **active `acceptance` job** (`pr_tests.yml`). The acceptance job
runs a matrix of `almalinux9` and `almalinux10` (`pr_tests.yml`) under
`BEAKER_HYPERVISOR: 'vagrant_libvirt'` (`pr_tests.yml`), driving
`bundle exec rake beaker:suites[default,<node>]` on a libvirt/QEMU Vagrant setup.

## Common commands

```sh
# Install dependencies
bundle install

# Run all unit tests
bundle exec rake spec

# Run the unit tests in parallel (as CI does)
bundle exec rake parallel_spec

# Puppet syntax + lint
bundle exec rake syntax
bundle exec rake lint

# Ruby lint
bundle exec rake rubocop

# Regenerate REFERENCE.md from puppet-strings docstrings
puppet strings generate --format markdown --out REFERENCE.md

# Run the default beaker acceptance suite against a nodeset
bundle exec rake beaker:suites[default,almalinux9]
```

Relevant gem pins (from `Gemfile`): `rubocop ~> 1.88.0` (`Gemfile`),
`puppetlabs_spec_helper ~> 8.0.0` (`Gemfile`), `simp-rake-helpers ~> 5.24.0`
(`Gemfile`), `simp-beaker-helpers ~> 2.0.0` (`Gemfile`). The default
tested version range is `>= 8 < 9` (`Gemfile`), and both the `openvox` and
`puppet` gems are installed for the transition (`Gemfile`).
`spec/spec_helper.rb` requires `puppetlabs_spec_helper/module_spec_helper`
(`spec_helper.rb`).

## Conventions

- **Compose `/etc/sudoers` from fragments, never from a single template.** New
  sudoers content should be a new `concat::fragment` (typically added via one of
  the existing defined types), with an `order` chosen to place it correctly in
  the file relative to aliases (10-16), `Defaults` (80), user specs (90), and
  `#includedir` (1000).
- **Preserve the `@summary` / `@param` puppet-strings docstrings** on classes
  and defined types — they drive `REFERENCE.md`. Regenerate `REFERENCE.md` after
  changing docs or parameters.
- **Keep the CVE-2019-14287 mitigation intact and conditional.** When touching
  runas handling, apply `sudo::update_runas_list` only for runas content and
  only on `sudo < 1.8.28` (gated on the `sudo_version` fact), as
  `alias.pp` / `default_entry.pp` / `user_specification.pp` already do.
- **Route SIMP feature toggles through
  `simplib::lookup('simp_options::*', { 'default_value' => ... })`** with an
  explicit default rather than assuming `simp_options` is included.
- **Templates are `.epp` (Puppet), not `.erb` (Ruby).** Keep the typed parameter
  block at the top of each template.
- Several baseline files carry a **puppetsync** notice — e.g. `Gemfile`, `spec/spec_helper.rb`, `.github/workflows/pr_tests.yml`, and the `.gitignore`/`.pdkignore` dotfiles — so they are baseline-managed and the next sync overwrites local edits. Check each file's header for the notice rather than treating this list as exhaustive; push changes to any such file upstream to the baseline, not here.
- Match the existing 2-space Puppet indentation and aligned-arrow parameter
  style used in the manifests.
