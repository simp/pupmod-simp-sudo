# == Define: sudo::default_entry
#
# Adds an entry to the defaults section of /etc/sudoers in order to override
# runtime defaults. See the 'Defaults' section of sudoers(5) for more
# information.
#
# == Parameters
#
# [*content*]
#   The content of this entry.
#
# [*target*]
#   The user, host, etc hash is the target of the content.  Leave
#   as 'nil' to not specify a target.
#
# [*def_type*]
#   May be one of:
#   - base => Global
#   - host => Host Entry
#   - user => User Entry
#   - runas => Runas Entry
#
# == Example
#
# To create the following defaults line in sudoers:
#    Defaults    requiretty, syslog=authpriv, !root_sudo, !umask, env_reset, env_keep = "COLORS DISPLAY HOSTNAME HISTSIZE INPUTRC KDEDIR \
#                        LS_COLORS MAIL PS1 PS2 QTDIR USERNAME \
#                        LANG LC_ADDRESS LC_CTYPE LC_COLLATE LC_IDENTIFICATION \
#                        LC_MEASUREMENT LC_MESSAGES LC_MONETARY LC_NAME LC_NUMERIC \
#                        LC_PAPER LC_TELEPHONE LC_TIME LC_ALL LANGUAGE LINGUAS \
#                        _XKB_CHARSET XAUTHORITY"
#
# Use the default_entry definition:
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
# == Authors
#
# * Trevor Vaughan <tvaughan@onyxpont.com>
#
define sudo::default_entry (
  $content,
  $target = 'nil',
  $def_type = 'base'
) {
  include 'sudo'

  simpcat_fragment { "sudoers+$name.default":
    content => template('sudo/defaults.erb')
  }

  if $target != 'nil' { validate_string($target) }
  validate_array_member($def_type, ['base', 'host', 'user', 'runas'])
}
