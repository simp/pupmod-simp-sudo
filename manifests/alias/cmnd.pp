# Convenience definition for adding a cmnd alias.
#
# @attr name
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
# @param validate
#   Whether to validate this file with a non-strict `visudo -cf` before it
#   is installed. Overrides the module-wide `sudo::validate` setting for
#   this resource.
#
# @param ensure
#   Set to `absent` to remove this entry's drop-in file. Simply deleting
#   the resource from your manifests/Hiera leaves the file (and the alias)
#   in place.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
define sudo::alias::cmnd (
  Array[String[1]]    $content,
  Optional[String[1]] $comment  = undef,
  Integer             $order    = 10,
  Optional[Boolean]   $validate = undef,
  Enum['present','absent'] $ensure = 'present',
) {
  sudo::alias { $name:
    ensure     => $ensure,
    content    => $content,
    order      => $order,
    comment    => $comment,
    validate   => $validate,
    alias_type => 'cmnd'
  }
}
