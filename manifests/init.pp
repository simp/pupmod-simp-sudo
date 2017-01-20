# Constructs a sudoers file based on configured aliases, defaults, and user
# specifications.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class sudo {
  package { 'sudo': ensure => 'latest' }

  concat { '/etc/sudoers':
    owner        => 'root',
    group        => 'root',
    mode         => '0440',
    validate_cmd => '/usr/sbin/visudo -q -c',
    require      => Package['sudo']
  }
}
