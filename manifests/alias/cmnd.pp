# Convenience definition for adding a cmnd alias.
#
# @param name
#   Becomes the unique alias name of your alias group
#
# @param content
#   A comma-separated list of commands that will comprise this alias.
#   For example: ['/usr/sbin/shutdown', '/usr/sbin/reboot']
#
# @param comment
#   Textual comment for this entry.
#
# @param order
#   If desired, force the order of this entry relative to other entries.
#   Usually not required.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
define sudo::alias::cmnd (
  Array[String]    $content,
  Optional[String] $comment = undef,
  Integer          $order   = 10
) {
  sudo::alias { $name:
    content    => $content,
    order      => $order,
    comment    => $comment,
    alias_type => 'cmnd'
  }
}
