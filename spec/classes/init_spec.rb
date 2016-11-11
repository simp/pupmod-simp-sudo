require 'spec_helper'
require 'yaml'

describe 'sudo' do

  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      let(:facts) do
        facts
      end

      it { should create_class('sudo') }

      it do
        should contain_simpcat_build('sudoers').with({
          'order'  => ['remote_sudoers', '*.alias', '*.default', '*.uspec'],
          'target' => '/etc/sudoers',
          #'onlyif' => Output of concat build
        })
      end

      it do
        should contain_file('/etc/sudoers').with({
          'ensure'    => 'file',
          'owner'     => 'root',
          'group'     => 'root',
          'mode'      => '0440',
          'backup'    => false,
          'audit'     => 'content',
          'subscribe' => 'Simpcat_build[sudoers]',
          'require'   => 'Package[sudo]'
        })
      end

      it { should contain_package('sudo') }

      context 'should create sudo::user_specification resources with an iterator' do
        context 'given something that is not a hash' do
          let(:params) {{
            :sudo_user_specification_hash => 'this is not a hash'
          }}
          it { is_expected.to raise_error }
        end

        context 'with properly formatted and complete yaml' do
          let(:params){
            YAML.load(<<-EOF
sudo_user_specification_hash:
  simp_sudosh:
    user_list:
      - simp
    cmnd: [ /usr/bin/sudosh ]
    runas: root
  users_yum:
    user_list:
      - '%users'
    cmnd:
      - yum
EOF
            )
          }
          it { is_expected.to create_sudo__user_specification('simp_sudosh').with({
            :user_list => ['simp'],
            :cmnd      => ['/usr/bin/sudosh'],
            :runas     => 'root',
            :setenv    => true
          })}
          it { is_expected.to create_sudo__user_specification('users_yum').with({
            :user_list => ['%users'],
            :cmnd      => ['yum'],
            :runas     => 'root',
            :setenv    => true
          })}
        end

        context 'with properly formatted yaml and default parameters' do
          let(:params){
            YAML.load(<<-EOF
sudo_user_specification_hash:
  simp_sudosh:
    user_list:
      - simp
    cmnd: [ /usr/bin/sudosh ]
    runas: root
  users_yum:
    user_list:
      - '%users'
    cmnd:
      - yum
sudo_user_specification_hash_defaults:
  runas: puppet
EOF
            )
          }
          it { is_expected.to create_sudo__user_specification('simp_sudosh').with({
            :user_list => ['simp'],
            :cmnd      => ['/usr/bin/sudosh'],
            :runas     => 'root',
            :setenv    => true
          })}
          it { is_expected.to create_sudo__user_specification('users_yum').with({
            :user_list => ['%users'],
            :cmnd      => ['yum'],
            :runas     => 'puppet',
            :setenv    => true
          })}
        end

      end

    end
  end

end
