# == Define: sudo::alias::cmnd
#
# Convenience definition for adding a cmnd alias.
#
# == Parameters
#
# [*name*]
#   Becomes the unique alias name of your alias group
#
# [*content*]
#   A comma-separated list of commands that will comprise this alias.
#   For example: ['/usr/sbin/shutdown', '/usr/sbin/reboot']
#
# [*comment*]
#   Textual comment for this entry.
#
# [*order*]
#   If desired, force the order of this entry relative to other entries.
#   Usually not required.
#
# == Author
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
define sudo::alias::cmnd (
  $content,
  $comment = 'nil',
  $order = '10'
) {
  sudo::alias { $name:
    content    => $content,
    order      => $order,
    comment    => $comment,
    alias_type => 'cmnd'
  }

  validate_string($comment)
  validate_integer($order)
}
