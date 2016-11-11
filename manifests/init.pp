# == Class: sudo
#
# Constructs a sudoers file based on configured aliases, defaults, and user
# specifications.
#
# == Parameters
#
# [*sudo_user_specification_hash*]
#   Default: {}
#   Type: Hash
#   A hash of sudo::user_specification resources that can be set in hiera
#   Example:
#     sudo_user_specification_hash:
#       simp_sudosh:
#         user_list:
#           - simp
#         cmnd: [ /usr/bin/sudosh ]
#         runas: root
#       users_yum:
#         user_list:
#           - '%users'
#         cmnd:
#           - yum
#
# [*sudo_user_specification_hash_defaults*]
#   Default: {}
#   Type: {}
#   Defaults parameters that will get merged with the data hash at compile time
#
# == Authors
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
class sudo (
  Hash $sudo_user_specification_hash = defined('$::sudo_user_specification_hash') ? { true => $sudo_user_specification_hash, default => hiera('sudo_user_specification_hash', {}) },
  Hash $sudo_user_specification_hash_defaults = {}
) {
  # This builds a local 'new' sudoers file.
  $outfile = simpcat_output('sudoers')

  simpcat_build { 'sudoers':
    order  => ['remote_sudoers', '*.alias', '*.default', '*.uspec'],
    target => '/etc/sudoers',
    onlyif => "/usr/sbin/visudo -q -c -f ${outfile}"
  }

  file { '/etc/sudoers':
    ensure    => 'file',
    owner     => 'root',
    group     => 'root',
    mode      => '0440',
    backup    => false,
    audit     => content,
    subscribe => Simpcat_build['sudoers'],
    require   => Package['sudo']
  }

  package {
    'sudo': ensure => 'latest'
  }

  if ! empty($sudo_user_specification_hash) {
    $sudo_user_specification_hash.each |$name, $spec| {
      sudo::user_specification { $name:
        * => $sudo_user_specification_hash_defaults + $spec
      }
    }
  }

}
