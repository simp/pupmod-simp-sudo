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
# @param package_ensure The ensure status of packages to be managed
#
# @author https://github.com/simp/pupmod-simp-sudo/graphs/contributors
#
class sudo (
  Hash   $user_specifications = {},
  Hash   $default_entries     = {},
  Hash   $aliases             = {},
  String $package_ensure      = simplib::lookup('simp_options::package_ensure', { 'default_value' => 'installed' }),
) {

  package { 'sudo':
    ensure => $package_ensure
  }

  concat { '/etc/sudoers':
    owner        => 'root',
    group        => 'root',
    mode         => '0440',
    validate_cmd => '/usr/sbin/visudo -q -c -f %',
    require      => Package['sudo']
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
}
