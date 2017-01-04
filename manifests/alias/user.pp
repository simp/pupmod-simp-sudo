# Convenience definition for adding a user alias.
#
# @attr name
#   Becomes the unique alias name of your alias group
#
# @param content
#   A comma-separated list of users that will comprise this alias.
#   For example: ['millert', 'mikef']
#
# @param comment
#   Textual comment for this entry
#
# @param order
#   If desired, force the order of this entry relative to other entries.
#   Usually not required.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
define sudo::alias::user (
  Array[String]    $content,
  Optional[String] $comment = undef,
  Integer          $order = 10
) {
  sudo::alias { $name:
    content    => $content,
    order      => $order,
    comment    => $comment,
    alias_type => 'user'
  }
}
