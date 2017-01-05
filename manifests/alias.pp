# Adds an alias to /etc/sudoers.
# See the 'Aliases' section of sudoers (5) for information about aliases
#
# @param content
#  The array of items that will be the content of this alias.
#  For example: 'administrators', 'wheel'
#
# @param alias_type
#  The type of alias to create.  One of 'user', 'runas', 'host' or 'cmnd'
#
# @param comment
#  Textual comment for this entry
#
# @param order
#  If desired, force the order of this entry relative to other entries.
#  Usually not required.
#
# @example To create the following alias in sudoers:
#     User_Alias FULLTIMERS = millert, mikef, dowdy
#   Use the alias definition:
#     alias { 'user_alias':
#       content => [ 'millert','mikef','dowdy' ],
#       alias_type => 'user'
#     }
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
define sudo::alias (
  Array[String[1]]    $content,
  Sudo::AliasType     $alias_type,
  Optional[String[1]] $comment     = undef,
  Integer             $order       = 10
) {
  include '::sudo'

  concat::fragment { "sudo_${alias_type}_alias_${name}":
    order   => $order,
    target  => '/etc/sudoers',
    content => template("${module_name}/alias.erb")
  }
}
