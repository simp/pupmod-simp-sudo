# _Description_
#
# Convenience definition for adding a user alias.
#
# _Variables_
# * $name
#   becomes the unique alias name of your alias group

# == Define: sudo::alias::user
#
# Convenience definition for adding a user alias.
#
# == Parameters
#
# [*name*]
#   Becomes the unique alias name of your alias group
#
# [*content*]
#   A comma-separated list of users that will comprise this alias.
#   For example: ['millert', 'mikef']
#
# [*comment*]
#   Textual comment for this entry
#
# [*order*]
#   If desired, force the order of this entry relative to other entries.
#   Usually not required.
#
# == Authors
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
define sudo::alias::user (
  $content,
  $comment = 'nil',
  $order = '10'
) {
  sudo::alias { $name:
    content    => $content,
    order      => $order,
    comment    => $comment,
    alias_type => 'user'
  }

  validate_string($comment)
  validate_integer($order)
}
