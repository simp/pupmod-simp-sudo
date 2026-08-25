# Add a user_spec entry to /etc/sudoers in order to determine which commands
# a user may run as the given user on the given host.
# See the 'User Specification' section of sudoers(5) for more information.
# Note that the 'Tag_Spec' entries have been explicitly noted below.
#
# @param user_list
#   Array of users or groups that should be able to execute a command.
#   Groups must be preceded by %.
#
# @param cmnd
#   Should be an array of commands you wan to run.
#
# @param host_list
#   Array of hosts where the specified users should be able to execute a command.
#
# @param runas
#   Can be an array of users that you need to be able to run the commands
#   as.  It will probably just be one user in most cases.
#
# @param passwd
#   Set PASSWD in /etc/sudoers
#
# @param doexec
#   Set EXEC in /etc/sudoers
#
# @param setenv
#   Set SETENV in /etc/sudoers
#
# @param options
#   Set additional options (such as SELinux role or type, date restrictions, or timeout)
#
# @param validate
#   Whether to validate this file with a non-strict `visudo -cf` before it
#   is installed. Overrides the module-wide `sudo::validate` setting for
#   this resource.
#
# @example To create the following in /etc/sudoers:
#   `simp, %simp_group    user2-dev1=(root) PASSWD:EXEC:SETENV: /bin/su root, /bin/su - root`
#   Use the user_specification definition:
#     sudo::user_specification { 'default_simp':
#       user_list => [ 'simp', '%simp_group' ],
#       runas     => 'root',
#       cmnd      => [ '/bin/su root', '/bin/su - root' ]
#     }
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
define sudo::user_specification (
  Array[String[1]]                    $user_list,
  Array[String[1]]                    $cmnd,
  Array[Simplib::Hostname,1]          $host_list  = [$facts['networking']['hostname'], $facts['networking']['fqdn']],
  Variant[String[1],Array[String[1]]] $runas      = ['root'],
  Boolean                             $passwd     = true,
  Boolean                             $doexec     = true,
  Boolean                             $setenv     = true,
  Hash                                $options    = {},
  Optional[Boolean]                   $validate   = undef,
) {
  include 'sudo'
  include 'sudo::config_check'
  include 'sudo::includedir'

  #  Check if this version is susceptable to cve_2019_14287
  if $facts['sudo_version'] and ( versioncmp($facts['sudo_version'], '1.8.28')  >= 0 ) {
    $_runas = $runas
  } else {
    $_runas =  sudo::update_runas_list($runas)
  }

  $_filename = sprintf('%04d_uspec_%s', 90, regsubst($name, '[^0-9A-Za-z_-]', '_', 'G'))

  $_validate_cmd = pick($validate, $sudo::validate) ? {
    true    => '/usr/sbin/visudo -cf %',
    default => undef,
  }

  $_file_content = epp(
    "${module_name}/uspec.epp",
    {
      'user_list' => $user_list,
      'cmnd'      => $cmnd,
      'host_list' => $host_list,
      'runas'     => $_runas,
      'passwd'    => $passwd,
      'doexec'    => $doexec,
      'setenv'    => $setenv,
      'options'   => $options,
    },
  )

  file { "${sudo::content_dir}/${_filename}":
    ensure       => 'file',
    owner        => 'root',
    group        => 'root',
    mode         => '0440',
    content      => $_file_content,
    validate_cmd => $_validate_cmd,
    require      => Package['sudo'],
  }

  if $sudo::strict_config_check {
    File["${sudo::content_dir}/${_filename}"] ~> Exec['visudo strict configuration check']
  }

  # sudo module 6.x wrote this same template output directly into
  # /etc/sudoers; remove any byte-identical stale lines so the drop-in
  # file is the single source of truth.
  if $sudo::remove_legacy_entries {
    $_file_content.split("\n").filter |$line| { $line =~ /\S/ }.each |$index, $line| {
      file_line { "sudo legacy cleanup ${_filename} ${index}":
        ensure  => absent,
        path    => '/etc/sudoers',
        line    => $line,
        require => Package['sudo'],
      }

      if $sudo::strict_config_check {
        File_line["sudo legacy cleanup ${_filename} ${index}"] ~> Exec['visudo strict configuration check']
      }
    }
  }
}
