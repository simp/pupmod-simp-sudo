# Adds an entry to the defaults section of /etc/sudoers in order to override
# runtime defaults. See the 'Defaults' section of sudoers(5) for more
# information.
#
# @param content
#   The content of this entry.
#
# @param target
#   The user, host, etc hash is the target of the content.  Leave
#   as undef to not specify a target.
#
# @param def_type
#   May be one of:
#   - base => Global
#   - cmnd => Cmnd Entry
#   - host => Host Entry
#   - user => User Entry
#   - runas => Runas Entry
#
# @param validate
#   Whether to validate this file with a non-strict `visudo -cf` before it
#   is installed. Overrides the module-wide `sudo::validate` setting for
#   this resource.
#
# @param ensure
#   Set to `absent` to remove this entry's drop-in file. Simply deleting
#   the resource from your manifests/Hiera leaves the file (and the
#   defaults line) in place -- this module is deliberately non-destructive
#   and never purges the content directory.
#
# @example To create the following defaults line in sudoers:
#   Defaults    requiretty, syslog=authpriv, !root_sudo, !umask, env_reset, env_keep = "COLORS DISPLAY HOSTNAME HISTSIZE INPUTRC KDEDIR \
#                        LS_COLORS MAIL PS1 PS2 QTDIR USERNAME \
#                        LANG LC_ADDRESS LC_CTYPE LC_COLLATE LC_IDENTIFICATION \
#                        LC_MEASUREMENT LC_MESSAGES LC_MONETARY LC_NAME LC_NUMERIC \
#                        LC_PAPER LC_TELEPHONE LC_TIME LC_ALL LANGUAGE LINGUAS \
#                        _XKB_CHARSET XAUTHORITY"
#
#   Use the default_entry definition:
#     sudo::default_entry { '00_main':
#         content => [ 'requiretty',
#             'syslog=authpriv',
#             '!root_sudo',
#             '!umask',
#             'env_reset',
#             'env_keep = "COLORS DISPLAY HOSTNAME HISTSIZE INPUTRC KDEDIR \
#                          LS_COLORS MAIL PS1 PS2 QTDIR USERNAME \
#                          LANG LC_ADDRESS LC_CTYPE LC_COLLATE LC_IDENTIFICATION \
#                          LC_MEASUREMENT LC_MESSAGES LC_MONETARY LC_NAME LC_NUMERIC \
#                          LC_PAPER LC_TELEPHONE LC_TIME LC_ALL LANGUAGE LINGUAS \
#                          _XKB_CHARSET XAUTHORITY"' ]
#     }
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
define sudo::default_entry (
  Array[String[1]]    $content,
  Optional[String[1]]      $target   = undef,
  Sudo::DefType            $def_type = 'base',
  Optional[Boolean]        $validate = undef,
  Enum['present','absent'] $ensure   = 'present',
) {
  include 'sudo'
  include 'sudo::config_check'
  include 'sudo::includedir'

  #  Check if this version is susceptable to cve_2019_14287
  if ( $def_type != 'runas' ) or ( $facts['sudo_version'] and ( versioncmp($facts['sudo_version'], '1.8.28' )  >= 0 )) {
    $_content = $content
  } else {
    $_content = sudo::update_runas_list($content)
  }

  $_filename = sprintf('%04d_default_%s', 80, sudo::safe_name($name))

  $_validate_cmd = pick($validate, $sudo::validate) ? {
    true    => '/usr/sbin/visudo -cf %',
    default => undef,
  }

  $_file_content = epp(
    "${module_name}/defaults.epp",
    {
      'content'  => $_content,
      'target'   => $target,
      'def_type' => $def_type,
    },
  )

  $_file_ensure = $ensure ? {
    'absent' => 'absent',
    default  => 'file',
  }

  file { "${sudo::normalized_content_dir}/${_filename}":
    ensure       => $_file_ensure,
    owner        => 'root',
    group        => 'root',
    mode         => '0440',
    content      => $_file_content,
    validate_cmd => $_validate_cmd,
    require      => Package['sudo'],
  }

  if $sudo::strict_config_check {
    File["${sudo::normalized_content_dir}/${_filename}"] ~> Exec['visudo strict configuration check']
  }

  # sudo module 6.x wrote this same template output directly into
  # /etc/sudoers; remove any byte-identical stale lines so the drop-in
  # file is the single source of truth.
  if $sudo::remove_legacy_entries {
    $_file_content.split("\n").filter |$line| { $line =~ /\S/ }.each |$index, $line| {
      file_line { "sudo legacy cleanup ${_filename} ${index}":
        ensure  => absent,
        path    => '/etc/sudoers',
        line    => $line,
        require => Package['sudo'],
      }

      if $sudo::strict_config_check {
        File_line["sudo legacy cleanup ${_filename} ${index}"] ~> Exec['visudo strict configuration check']
      }
    }
  }
}
