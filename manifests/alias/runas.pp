# == Define: sudo::alias::runas
#
# Convenience definition for adding a runas alias.
#
# == Parameters
#
# [*name*]
#   Becomes the unique alias name of your alias group
#
# [*content*]
#   A comma-separated list of hostnames or IP addresses that will comprise the alias.
#   For example: ['millert', 'mikef']
#
# [*comment*]
#   Textual comment for this entry
#
# [*order*]
#   If desired, force the order of this entry relative to other entries.
#   Usually not required.
#
# == Author
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
define sudo::alias::runas (
  $content,
  $comment = 'nil',
  $order = '10'
) {
  sudo::alias { $name:
    content    => $content,
    order      => $order,
    comment    => $comment,
    alias_type => 'runas'
  }

  validate_string($comment)
  validate_integer($order)
}
