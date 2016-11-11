require 'spec_helper'

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
          let(:hieradata){ 'sudo__user_specifications' }
          it { is_expected.to create_sudo__user_specification('simp_sudosh').with({
            :user_list => ['simp'],
            :host_list => ['hostname'],
            :cmnd      => ['/usr/bin/sudosh'],
          })}
          it { is_expected.to create_sudo__user_specification('users_yum_update').with({
            :user_list => ['%users'],
            :cmnd      => ['yum update'],
          })}
          it { is_expected.to create_sudo__user_specification('test_resource').with({
            :user_list => ['simp'],
            :host_list => ['hostname'],
            :cmnd      => ['w'],
            :runas     => 'root',
            :passwd    => true,
          })}
        end

      end

    end
  end

end
