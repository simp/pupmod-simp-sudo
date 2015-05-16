# == Define: sudo::user_specification
#
# Add a user_spec entry to /etc/sudoers in order to determine which commands
# a user may run as the given user on the given host.
# See the 'User Specification' section of sudoers(5) for more information.
# Note that the 'Tag_Spec' entries have been explicitly noted below.
#
# == Parameters
#
# [*user_list*]
#   Array of users or groups that should be able to execute a command.
#
# [*cmnd*]
#   Should be an array of commands you wan to run.
#
# [*host_list*]
#   Array of hosts where the specified users should be able to execute a command.
#
# [*runas*]
#   Can be an array of users that you need to be able to run the commands
#   as.  It will probably just be one user in most cases.
#
# [*passwd*]
#   Set PASSWD in /etc/sudoers
#
# [*doexec*]
#   Set EXEC in /etc/sudoers
#
# [*setenv*]
#   Set SETENV in /etc/sudoers
#
# == Example
#
# To create the following in /etc/sudoers:
#    simp    user2-dev1=(root) PASSWD:EXEC:SETENV: /bin/su root, /bin/su - root
# Use the user_specification definition:
#     sudo::user_specification { 'default_simp':
#       user_list => 'simp',
#       runas => 'root',
#       cmnd => [ '/bin/su root', '/bin/su - root' ]
#     }
#
# == Authors
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
define sudo::user_specification (
  $user_list,
  $cmnd,
  $host_list = [$::hostname],
  $runas = 'root',
  $passwd = true,
  $doexec = true,
  $setenv = true
) {
  include 'sudo'

  concat_fragment { "sudoers+$name.uspec":
    content => template('sudo/uspec.erb')
  }

  validate_string($runas)
  validate_bool($passwd)
  validate_bool($doexec)
  validate_bool($setenv)
}
