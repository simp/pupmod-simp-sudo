# Adds an alias to /etc/sudoers.
# See the 'Aliases' section of sudoers (5) for information about aliases
#
# @param content
#  The array of items that will be the content of this alias.
#  For example: 'administrators', 'wheel'
#
# @param alias_type
#  The type of alias to create.  One of 'user', 'runas', 'host' or 'cmnd'
#
# @param comment
#  Textual comment for this entry
#
# @param order
#  If desired, force the order of this entry relative to other entries.
#  Usually not required.
#
# @param validate
#  Whether to validate this file with a non-strict `visudo -cf` before it
#  is installed. Overrides the module-wide `sudo::validate` setting for
#  this resource.
#
# @param ensure
#  Set to `absent` to remove this entry's drop-in file. Simply deleting
#  the resource from your manifests/Hiera leaves the file (and the alias)
#  in place -- this module is deliberately non-destructive and never
#  purges the content directory.
#
# @example To create the following alias in sudoers:
#     User_Alias FULLTIMERS = millert, mikef, dowdy
#   Use the alias definition:
#     alias { 'user_alias':
#       content => [ 'millert','mikef','dowdy' ],
#       alias_type => 'user'
#     }
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
define sudo::alias (
  Array[String[1]]    $content,
  Sudo::AliasType     $alias_type,
  Optional[String[1]]      $comment  = undef,
  Integer                  $order    = 10,
  Optional[Boolean]        $validate = undef,
  Enum['present','absent'] $ensure   = 'present',
) {
  include 'sudo'
  include 'sudo::config_check'
  include 'sudo::includedir'

  #  Check if this version is susceptable to cve_2019_14287
  if ($alias_type != 'runas' ) or ( $facts['sudo_version'] and versioncmp($facts['sudo_version'], '1.8.28' ) >= 0 ) {
    $_content = $content
  } else {
    $_content = sudo::update_runas_list($content)
  }

  $_filename = sprintf('%04d_%s_alias_%s', $order, $alias_type, sudo::safe_name($name))

  $_validate_cmd = pick($validate, $sudo::validate) ? {
    true    => '/usr/sbin/visudo -cf %',
    default => undef,
  }

  $_file_content = epp(
    "${module_name}/alias.epp",
    {
      'content'    => $_content,
      'alias_type' => $alias_type,
      'comment'    => $comment,
      'name'       => $name,
    },
  )

  $_file_ensure = $ensure ? {
    'absent' => 'absent',
    default  => 'file',
  }

  file { "${sudo::normalized_content_dir}/${_filename}":
    ensure       => $_file_ensure,
    owner        => 'root',
    group        => 'root',
    mode         => '0440',
    content      => $_file_content,
    validate_cmd => $_validate_cmd,
    require      => Package['sudo'],
  }

  if $sudo::strict_config_check {
    File["${sudo::normalized_content_dir}/${_filename}"] ~> Exec['visudo strict configuration check']
  }

  # sudo module 6.x wrote this same template output directly into
  # /etc/sudoers; remove any byte-identical stale lines so the drop-in
  # file is the single source of truth (a duplicate alias definition is a
  # sudoers parse error).
  if $sudo::remove_legacy_entries {
    $_file_content.split("\n").filter |$line| { $line =~ /\S/ }.each |$index, $line| {
      # `before` makes the first post-upgrade converge fail closed: the
      # legacy line is removed before the drop-in goes live, so sudo never
      # sees the entry defined twice (a duplicate alias definition is a
      # parse error that would disable sudo entirely until cleanup ran).
      file_line { "sudo legacy cleanup ${_filename} ${index}":
        ensure  => absent,
        path    => '/etc/sudoers',
        line    => $line,
        require => Package['sudo'],
        before  => File["${sudo::normalized_content_dir}/${_filename}"],
      }

      if $sudo::strict_config_check {
        File_line["sudo legacy cleanup ${_filename} ${index}"] ~> Exec['visudo strict configuration check']
      }
    }
  }
}
