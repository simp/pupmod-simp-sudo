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
#     ---
#     sudo::user_specifications:
#       defaults:
#         host_list:
#           - hostname
#         cmnd: [ /usr/bin/sudosh ]
#       test:
#       testhost:
#         host_list:
#           - otherhost
#       '%group':
#
# == Authors
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
class sudo (
  Hash $user_specifications = {}
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

  if ! empty($user_specifications) {
    # extract defaults and remove that hash from iteration
    $defaults  = $user_specifications['defaults']
    $raw_specs = $user_specifications - 'defaults'

    $raw_specs.each |$name, $options| {
      if is_hash($options) {
        $args = $options
      }
      else {
        $args = {}
      }
      inspect($args)
      inspect($user_specifications)
      sudo::user_specification {
        default: * => $defaults;
        $name:   * => $args;
      }
    }
  }

}
