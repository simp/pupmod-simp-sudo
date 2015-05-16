# == Define: sudo::alias::host
#
# Convenience definition for adding a host alias.
#
# == Parameters
#
# [*name*]
#   Becomes the unique alias name of your alias group
#
# [*content*]
#   A comma-separated list of hostnames or IP addresses that will comprise the
#   alias.
#   For example: ['1.2.3.4', '5.6.7.8'] or ['mail', 'www']
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
# Trevor Vaughan <tvaughan@onyxpoint.com>
#
define sudo::alias::host (
  $content,
  $comment = 'nil',
  $order = '10'
) {
  sudo::alias { $name:
    content    => $content,
    order      => $order,
    comment    => $comment,
    alias_type => 'host'
  }

  validate_string($comment)
  validate_integer($order)
}
