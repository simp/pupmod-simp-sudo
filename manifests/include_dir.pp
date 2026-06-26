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

  $_filename = sprintf('%04d_includedir_%s', 1000, regsubst($include_dir, '[^0-9A-Za-z_-]', '_', 'G'))

  file { "${sudo::content_dir}/${_filename}":
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0440',
    content => "#includedir ${include_dir}\n",
    require => Package['sudo'],
  }
}
