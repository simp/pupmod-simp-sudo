# Add include directories to /etc/sudoers
#
# @param include_dir
#   The directory to include in /etc/sudoers. Trailing slashes are
#   stripped. When this equals `sudo::content_dir`, no drop-in file is
#   written: `sudo::manage_includedir` already ensures /etc/sudoers reads
#   the content directory, and a drop-in *inside* the content directory
#   that includes the content directory again would make sudo fail with
#   'too many levels of includes' -- a complete sudo lockout.
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
# @param ensure
#   Set to `absent` to remove this resource's `#includedir` drop-in file.
#   The include directory itself is never removed. Simply deleting the
#   resource from your manifests/Hiera leaves the drop-in in place -- this
#   module is deliberately non-destructive and never purges the content
#   directory.
#
define sudo::include_dir (
  Stdlib::Absolutepath     $include_dir,
  Boolean                  $tidy_include_dir = false,
  Optional[Boolean]        $validate         = undef,
  Enum['present','absent'] $ensure           = 'present',
) {
  include 'sudo'
  include 'sudo::config_check'
  include 'sudo::includedir'

  $_include_dir = regsubst($include_dir, '(?<!^)/+$', '')

  # Unlike the entry defines, no legacy-line cleanup happens here: the
  # `#includedir` line 6.x wrote into /etc/sudoers may be the very
  # directive that keeps this module's drop-in files active (and would
  # conflict with the line sudo::includedir ensures present).

  # 0750 matches the distribution default for /etc/sudoers.d. Recursion is
  # only enabled when purging: it would otherwise force this mode onto
  # pre-existing unmanaged files (simp/pupmod-simp-sudo#138). Drop-in files
  # managed by this module are 0440 via their own resources.
  file { $_include_dir:
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0750',
    purge   => $tidy_include_dir,
    recurse => $tidy_include_dir,
  }

  # A drop-in that re-includes the directory it lives in makes sudo fail
  # with 'too many levels of includes'. The directive for the content
  # directory is already ensured by sudo::includedir, so the drop-in is
  # redundant there and is skipped.
  if $_include_dir != $sudo::normalized_content_dir {
    $_filename = sprintf('%04d_includedir_%s', 1000, sudo::safe_name($_include_dir))

    $_validate_cmd = pick($validate, $sudo::validate) ? {
      true    => '/usr/sbin/visudo -cf %',
      default => undef,
    }

    $_file_ensure = $ensure ? {
      'absent' => 'absent',
      default  => 'file',
    }

    file { "${sudo::normalized_content_dir}/${_filename}":
      ensure       => $_file_ensure,
      owner        => 'root',
      group        => 'root',
      mode         => '0440',
      content      => "#includedir ${_include_dir}\n",
      validate_cmd => $_validate_cmd,
      require      => Package['sudo'],
    }

    if $sudo::strict_config_check {
      File["${sudo::normalized_content_dir}/${_filename}"] ~> Exec['visudo strict configuration check']
    }
  }
}
