# Declares the strict whole-configuration check (`visudo -cs`) that managed
# sudoers drop-in files notify when they change. Included by this module's
# defined types; declares nothing when `sudo::strict_config_check` is false.
#
# @api private
class sudo::config_check {
  assert_private()

  include 'sudo'

  if $sudo::strict_config_check {
    # -f names the standard sudoers file explicitly because it also makes
    # visudo skip its owner/mode checks, which would otherwise fail on
    # pre-existing unmanaged drop-ins with lax permissions (Vagrant and
    # cloud images commonly ship one). Only the strict parse is wanted here.
    exec { 'visudo strict configuration check':
      command     => '/usr/sbin/visudo -csf /etc/sudoers',
      refreshonly => true,
      logoutput   => true,
      require     => Package['sudo'],
    }
  }
}
