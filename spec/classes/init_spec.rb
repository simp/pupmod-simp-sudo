require 'spec_helper'

describe 'sudo' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        context 'with default parameters' do
          it { is_expected.to create_class('sudo') }
          it { is_expected.to contain_package('sudo') }
          it { is_expected.to contain_concat('/etc/sudoers') }
        end

        context 'should create sudo::user_specification resources with an iterator' do
          context 'with properly formatted and complete yaml' do
            let(:hieradata) { 'sudo__user_specifications' }
            it { is_expected.to create_sudo__user_specification('simp_sudosh').with({
              :user_list => ['simp'],
              :cmnd      => ['/usr/bin/sudosh'],
            })}
            it { is_expected.to create_sudo__user_specification('users_yum_update').with({
              :user_list => ['%users'],
              :cmnd      => ['yum update'],
            })}
            it { is_expected.to create_sudo__user_specification('test_resource').with({
              :user_list => ['%group'],
              :cmnd      => ['w'],
              :runas     => 'root',
              :passwd    => true,
            })}
          end
        end

      end
    end
  end
end
