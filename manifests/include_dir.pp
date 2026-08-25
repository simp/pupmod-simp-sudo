# Add include directories to /etc/sudoers
#
# @param include_dir the directory to include in /etc/sudoers
#
# @param tidy_include_dir
#   Whether to purge files in $include_dir that are not managed by Puppet
#
# @param validate
#   Whether to validate the generated `#includedir` file with a non-strict
#   `visudo -cf` before it is installed. Overrides the module-wide
#   `sudo::validate` setting for this resource.
#
define sudo::include_dir (
  Stdlib::Absolutepath $include_dir,
  Boolean              $tidy_include_dir = false,
  Optional[Boolean]    $validate         = undef,
) {
  include 'sudo'
  include 'sudo::config_check'

  file { $include_dir:
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    purge   => $tidy_include_dir,
    recurse => true,
  }

  $_filename = sprintf('%04d_includedir_%s', 1000, regsubst($include_dir, '[^0-9A-Za-z_-]', '_', 'G'))

  $_validate_cmd = pick($validate, $sudo::validate) ? {
    true    => '/usr/sbin/visudo -cf %',
    default => undef,
  }

  file { "${sudo::content_dir}/${_filename}":
    ensure       => 'file',
    owner        => 'root',
    group        => 'root',
    mode         => '0440',
    content      => "#includedir ${include_dir}\n",
    validate_cmd => $_validate_cmd,
    require      => Package['sudo'],
  }

  if $sudo::strict_config_check {
    File["${sudo::content_dir}/${_filename}"] ~> Exec['visudo strict configuration check']
  }
}
