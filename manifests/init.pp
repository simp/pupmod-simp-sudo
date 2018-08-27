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
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class sudo (
  Optional[Hash] $user_specifications = undef
){
  package { 'sudo': ensure => 'latest' }

  concat { '/etc/sudoers':
    owner        => 'root',
    group        => 'root',
    mode         => '0440',
    validate_cmd => '/usr/sbin/visudo -q -c -f %',
    require      => Package['sudo']
  }

  if $user_specifications {
    $user_specifications.each |$spec, $options| {
      $args = $options ? { Hash => $options, default => {} }
      sudo::user_specification {
        $spec: * => $args;
      }
    }
  }

}
