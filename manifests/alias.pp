# == Define: sudo::alias
#
# Adds an alias to /etc/sudoers.
# See the 'Aliases' section of sudoers (5) for information about aliases
#
# == Parameters
#
# [*content*]
#  The comma-separated array of items that will be the content of this alias.
#  For example: 'administrators', 'wheel'
#
# [*alias_type*]
#  The type of alias to create.  One of 'user', 'runas', 'host' or 'cmnd'
#
# [*comment*]
#  Textual comment for this entry
#
# [*order*]
#  If desired, force the order of this entry relative to other entries.
#  Usually not required.
#
# == Examples
#
# To create the following alias in sudoers:
#     User_Alias FULLTIMERS = millert, mikef, dowdy
# Use the alias definition:
#     alias { 'user_alias':
#       content => [ 'millert','mikef','dowdy' ],
#       alias_type => 'user'
#     }
#
# == Authors
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
define sudo::alias (
  $content,
  $alias_type,
  $comment = 'nil',
  $order = '10'
) {
  include 'sudo'

  simpcat_fragment { "sudoers+${alias_type}_${name}_${order}.alias":
    content => template('sudo/alias.erb')
  }

  validate_array_member($alias_type, ['user', 'runas', 'host', 'cmnd'])
  validate_string($comment)
  validate_integer($order)
}
