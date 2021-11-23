# Add include directories to /etc/sudoers
#
# @param include_dir the directory to include in /etc/sudoers
#
define sudo::include_dir (
  Stdlib::Absolutepath $include_dir = '',
) {
  file { $include_dir:
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    recurse => true,
  }
  concat::fragment { 'sudo_include_dir_$include_dir':
    order   => 1000,
    target  => '/etc/sudoers',
    content => "include ${include_dir}",
  }
}
