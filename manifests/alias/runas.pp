# Convenience definition for adding a runas alias.
#
# @attr name
#   Becomes the unique alias name of your alias group
#
# @param content
#   A comma-separated list of hostnames or IP addresses that will comprise the alias.
#   For example: ['millert', 'mikef']
#
# @param comment
#   Textual comment for this entry
#
# @param order
#   If desired, force the order of this entry relative to other entries.
#   Usually not required.
#
# @param validate
#   Whether to validate this file with a non-strict `visudo -cf` before it
#   is installed. Overrides the module-wide `sudo::validate` setting for
#   this resource.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
define sudo::alias::runas (
  Array[String[1]]    $content,
  Optional[String[1]] $comment  = undef,
  Integer             $order    = 14,
  Optional[Boolean]   $validate = undef,
) {
  sudo::alias { $name:
    content    => $content,
    order      => $order,
    comment    => $comment,
    validate   => $validate,
    alias_type => 'runas'
  }
}
