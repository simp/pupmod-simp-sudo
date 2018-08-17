# Add a user_spec entry to /etc/sudoers in order to determine which commands
# a user may run as the given user on the given host.
# See the 'User Specification' section of sudoers(5) for more information.
# Note that the 'Tag_Spec' entries have been explicitly noted below.
#
# @param user_list
#   Array of users or groups that should be able to execute a command.
#   Groups must be preceded by %.
#
# @param cmnd
#   Should be an array of commands you wan to run.
#
# @param host_list
#   Array of hosts where the specified users should be able to execute a command.
#
# @param runas
#   Can be an array of users that you need to be able to run the commands
#   as.  It will probably just be one user in most cases.
#
# @param passwd
#   Set PASSWD in /etc/sudoers
#
# @param doexec
#   Set EXEC in /etc/sudoers
#
# @param setenv
#   Set SETENV in /etc/sudoers
#
# @example To create the following in /etc/sudoers:
#   `simp, %simp_group    user2-dev1=(root) PASSWD:EXEC:SETENV: /bin/su root, /bin/su - root`
#   Use the user_specification definition:
#     sudo::user_specification { 'default_simp':
#       user_list => 'simp, %simp_group',
#       runas     => 'root',
#       cmnd      => [ '/bin/su root', '/bin/su - root' ]
#     }
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
define sudo::user_specification (
  Array[String[1]]         $user_list,
  Array[String[1]]         $cmnd,
  Array[Simplib::Hostname,1] $host_list = [$facts['hostname'], $facts['fqdn']],
  String[1]                $runas     = 'root',
  Boolean                  $passwd    = true,
  Boolean                  $doexec    = true,
  Boolean                  $setenv    = true
) {
  include '::sudo'

  concat::fragment { "sudo_user_specification_${name}":
    order   => 90,
    target  => '/etc/sudoers',
    content => template("${module_name}/uspec.erb")
  }
}
