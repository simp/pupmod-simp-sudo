# Constructs a sudoers file based on configured aliases, defaults, and user
# specifications.
#
# @param user_specifications
#   `sudo::user_specification` resources to declare, as a Hash of resource
#   title to that define's parameters. Each entry is written as its own
#   drop-in file under `$content_dir`.
#
#   Deleting an entry from Hiera leaves its file, and the rule, in place.
#   Set `ensure: absent` on the entry to remove it, keeping its required
#   parameters in the same or a lower Hiera layer. The Hash is merged with
#   `deep`, so a higher layer can remove one entry without restating the
#   others. Arrays inside entries are unioned, not replaced: to narrow one,
#   set the old entry to `ensure: absent` and declare a new entry under a
#   new title.
#
# @param default_entries
#   `sudo::default_entry` resources to declare, as a Hash of resource title
#   to that define's parameters. Each entry writes one `Defaults` line as
#   its own drop-in file under `$content_dir`. Removal and merging work as
#   for `user_specifications`.
#
# @param aliases
#   `sudo::alias` resources to declare, as a Hash of resource title to that
#   define's parameters. The title is the alias name (upcased in the file).
#   Each entry writes one `User_Alias`, `Runas_Alias`, `Host_Alias` or
#   `Cmnd_Alias` line as its own drop-in file under `$content_dir`. Removal
#   and merging work as for `user_specifications`.
#
# @param include_dirs an array of paths to include in the sudoers file
#
# @param package_ensure The ensure status of packages to be managed
#
# @param content_dir
#   The directory under which this module writes its managed sudoers
#   drop-in files. Defaults to `/etc/sudoers.d`, which sudo reads via the
#   distribution's `#includedir` directive. Each managed entry is written as
#   its own file here, so the shared `/etc/sudoers` is never owned by this
#   module. Trailing slashes are stripped, so `/etc/sudoers.d/` and
#   `/etc/sudoers.d` are equivalent.
#
# @param validate
#   Whether to validate each managed drop-in file with a non-strict
#   `visudo -cf` before it is installed. Non-strict validation rejects
#   genuine syntax errors and unknown Defaults options, but tolerates
#   references to aliases defined in other files (they only produce
#   warnings), so entries may still be split across multiple files. Can be
#   overridden per resource via the defines' `validate` parameter.
#
# @param manage_includedir
#   Whether to ensure `/etc/sudoers` contains an `#includedir` directive
#   for `$content_dir` whenever this module manages at least one entry.
#   The line is only appended (via `file_line`) when no equivalent
#   `#includedir`/`@includedir` directive is already present, and never on
#   a bare `include sudo`. This matters on systems upgraded from version
#   6.x of this module, where the previously concat-managed `/etc/sudoers`
#   may lack the OS-shipped directive — without it, the drop-in files
#   under `$content_dir` are silently ignored by sudo. If you disable
#   this, you are responsible for ensuring the directive exists by other
#   means; a warning is logged whenever entries are managed with this
#   disabled.
#
# @param remove_legacy_entries
#   Whether to remove lines from `/etc/sudoers` that are byte-identical to
#   entry content this module now writes as drop-in files under
#   `$content_dir`. Version 6.x of this module wrote entries directly into
#   `/etc/sudoers` using the same templates, so after an upgrade those
#   stale lines duplicate the drop-in content — and duplicate alias
#   definitions are a sudoers parse error. Only exact duplicates of
#   currently-managed content are removed; nothing else in `/etc/sudoers`
#   is touched.
#
# @param strict_config_check
#   Whether a change to any managed drop-in file should trigger a strict
#   check (`visudo -cs`) of the complete assembled sudo configuration. This
#   runs after the files are written, so it cannot prevent an invalid
#   configuration from landing, but it catches cross-file problems that
#   per-file validation cannot see (such as removing an alias that a user
#   specification in another file still references) and fails the Puppet
#   run so the problem is visible. Disable this if your site intentionally
#   carries unresolved alias references.
#
# @example Manage sudoers entries from Hiera
#   ---
#   sudo::aliases:
#     admins:
#       alias_type: user
#       content: ['alice', 'bob']
#   sudo::default_entries:
#     logging:
#       content: ['syslog=authpriv', 'log_output']
#   sudo::user_specifications:
#     admins_all:
#       user_list: ['ADMINS']
#       cmnd: ['ALL']
#
# @example Remove an entry set in a lower Hiera layer
#   ---
#   sudo::user_specifications:
#     admins_all:
#       ensure: absent
#
# @author https://github.com/simp/pupmod-simp-sudo/graphs/contributors
#
class sudo (
  Hash                        $user_specifications = {},
  Hash                        $default_entries     = {},
  Hash                        $aliases             = {},
  String[1]                   $package_ensure      = 'installed',
  Array[Stdlib::Absolutepath] $include_dirs        = [],
  Stdlib::Absolutepath        $content_dir         = '/etc/sudoers.d',
  Boolean                     $validate              = true,
  Boolean                     $strict_config_check   = true,
  Boolean                     $manage_includedir     = true,
  Boolean                     $remove_legacy_entries = true,
) {
  # Normalized once here and used for all path construction and includedir
  # directive matching: Stdlib::Absolutepath accepts a trailing slash,
  # which would otherwise leak into drop-in paths and make the directive
  # match in sudo::includedir miss the stock `#includedir /etc/sudoers.d`.
  $normalized_content_dir = regsubst($content_dir, '(?<!^)/+$', '')

  package { 'sudo':
    ensure => $package_ensure
  }

  $user_specifications.each |$spec, $options| {
    sudo::user_specification { $spec:
      * => $options,
    }
  }

  $default_entries.each |$key, $value| {
    sudo::default_entry { $key:
      * => $value,
    }
  }

  $aliases.each |$key, $value| {
    sudo::alias { $key:
      * => $value,
    }
  }

  $include_dirs.each | $include_dir | {
    sudo::include_dir { $include_dir:
      include_dir => $include_dir,
    }
  }
}
