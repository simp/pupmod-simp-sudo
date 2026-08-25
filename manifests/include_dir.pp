# Add include directories to /etc/sudoers
#
# @param include_dir the directory to include in /etc/sudoers
#
# @param tidy_include_dir
#   Whether to purge files in $include_dir that are not managed by Puppet.
#   Only when this is enabled does Puppet recurse into the directory at
#   all; otherwise pre-existing unmanaged files are left completely
#   untouched (their ownership and permissions are not modified).
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
  include 'sudo::includedir'

  # Unlike the entry defines, no legacy-line cleanup happens here: the
  # `#includedir` line 6.x wrote into /etc/sudoers may be the very
  # directive that keeps this module's drop-in files active (and would
  # conflict with the line sudo::includedir ensures present).

  # 0750 matches the distribution default for /etc/sudoers.d. Recursion is
  # only enabled when purging: it would otherwise force this mode onto
  # pre-existing unmanaged files (simp/pupmod-simp-sudo#138). Drop-in files
  # managed by this module are 0440 via their own resources.
  file { $include_dir:
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0750',
    purge   => $tidy_include_dir,
    recurse => $tidy_include_dir,
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
