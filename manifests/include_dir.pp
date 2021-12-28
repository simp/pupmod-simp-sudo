# Add include directories to /etc/sudoers
#
# @param include_dir the directory to include in /etc/sudoers
#
define sudo::include_dir (
  Stdlib::Absolutepath $include_dir,
  Boolean                        $tidy_include_dir = false,
) {
  include 'sudo'

  file { $include_dir:
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    purge   => $tidy_include_dir,
    recurse => true,
  }

  concat::fragment { "sudo_include_dir_${include_dir}":
    order   => 1000,
    target  => '/etc/sudoers',
    content => "#includedir ${include_dir}",
  }
}
