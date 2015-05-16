# == Class: sudo
#
# Constructs a sudoers file based on configured aliases, defaults, and user
# specifications.
#
# == Parameters
#
# == Authors
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
class sudo {
  # This builds a local 'new' sudoers file.
  $outfile = concat_output('sudoers')

  concat_build { 'sudoers':
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
    subscribe => Concat_build['sudoers'],
    require   => Package['sudo']
  }

  package {
    'sudo': ensure => 'latest'
  }
}
