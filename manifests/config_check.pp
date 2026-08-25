# Declares the strict whole-configuration check (`visudo -cs`) that managed
# sudoers drop-in files notify when they change. Included by this module's
# defined types; declares nothing when `sudo::strict_config_check` is false.
#
# @api private
class sudo::config_check {
  assert_private()

  include 'sudo'

  if $sudo::strict_config_check {
    exec { 'visudo strict configuration check':
      command     => '/usr/sbin/visudo -cs',
      refreshonly => true,
      logoutput   => true,
      require     => Package['sudo'],
    }
  }
}
