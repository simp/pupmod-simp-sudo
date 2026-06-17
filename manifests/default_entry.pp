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
  Optional[String[1]] $target   = undef,
  Sudo::DefType       $def_type = 'base',
) {
  include 'sudo'

  #  Check if this version is susceptable to cve_2019_14287
  if ( $def_type != 'runas' ) or ( $facts['sudo_version'] and ( versioncmp($facts['sudo_version'], '1.8.28' )  >= 0 )) {
    $_content = $content
  } else {
    $_content = sudo::update_runas_list($content)
  }

  $_filename = sprintf('%04d_default_%s', 80, regsubst($name, '[^0-9A-Za-z_-]', '_', 'G'))

  file { "${sudo::content_dir}/${_filename}":
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0440',
    content => epp(
      "${module_name}/defaults.epp",
      {
        'content'  => $_content,
        'target'   => $target,
        'def_type' => $def_type,
      },
    ),
    require => Package['sudo'],
  }
}
