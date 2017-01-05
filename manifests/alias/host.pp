# Convenience definition for adding a host alias.
#
# @attr name
#   Becomes the unique alias name of your alias group
#
# @param content
#   A comma-separated list of hostnames or IP addresses that will comprise the
#   alias.
#   For example: ['1.2.3.4', '5.6.7.8'] or ['mail', 'www']
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
define sudo::alias::host (
  Array[String[1]]    $content,
  Optional[String[1]] $comment  = undef,
  Integer             $order    = 12
) {
  sudo::alias { $name:
    content    => $content,
    order      => $order,
    comment    => $comment,
    alias_type => 'host'
  }
}
