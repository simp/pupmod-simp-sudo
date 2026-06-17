# Constructs a sudoers file based on configured aliases, defaults, and user
# specifications.
#
# @param user_specifications
#   A hash of sudo::user_specification resources that can be set in hiera
#   Example:
#     ---
#     sudo::user_specifications:
#       simp_su:
#         user_list: ['simp']
#         cmnd: ['/bin/su']
#       users_yum_update:
#         user_list:
#           - '%users'
#         cmnd:
#           - 'yum update'
#       test_resource:
#         user_list: ['%group']
#         cmnd: ['w']
#         runas: root
#         passwd: true
#
# @param include_dirs an array of paths to include in the sudoers file
#
# @param package_ensure The ensure status of packages to be managed
#
# @param content_dir
#   The directory under which this module writes its managed sudoers
#   drop-in files. Defaults to `/etc/sudoers.d`, which sudo reads via the
#   distribution's `#includedir` directive. Each managed entry is written as
#   its own file here, so the shared `/etc/sudoers` is never owned by this
#   module.
#
# @author https://github.com/simp/pupmod-simp-sudo/graphs/contributors
#
class sudo (
  Hash                        $user_specifications = {},
  Hash                        $default_entries     = {},
  Hash                        $aliases             = {},
  String[1]                   $package_ensure      = 'installed',
  Array[Stdlib::Absolutepath] $include_dirs        = [],
  Stdlib::Absolutepath        $content_dir         = '/etc/sudoers.d',
) {

  package { 'sudo':
    ensure => $package_ensure
  }

  $user_specifications.each |$spec, $options| {
    sudo::user_specification { $spec:
      * => $options,
    }
  }

  $default_entries.each |$key, $value| {
    sudo::default_entry { $key:
      * => $value,
    }
  }

  $aliases.each |$key, $value| {
    sudo::alias { $key:
      * => $value,
    }
  }

  $include_dirs.each | $include_dir | {
    sudo::include_dir { $include_dir:
      include_dir => $include_dir,
    }
  }
}
