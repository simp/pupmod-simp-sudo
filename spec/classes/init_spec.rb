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
            it { is_expected.to create_sudo__user_specification('simp_su').with({
              :user_list => ['simp'],
              :cmnd      => ['/bin/su'],
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

        context 'should create sudo::default_entry resources with an iterator' do
          context 'with properly formatted and complete yaml' do
            let(:hieradata) { 'sudo__default_entries' }
            it { is_expected.to create_sudo__default_entry('00_main').with({
              :content  => ['requiretty','syslog=authpriv'],
              :def_type => 'base',
            })}
            it { is_expected.to create_sudo__default_entry('host_override').with({
              :content  => ['passwd_timeout=0.017'],
              :target   => 'SERVERS',
              :def_type => 'host',
            })}
          end
        end

        context 'should create sudo::alias resources with an iterator' do
          context 'with properly formatted and complete yaml' do
            let(:hieradata) { 'sudo__aliases' }
            it { is_expected.to create_sudo__alias('user_alias').with({
              :content    => ['user1','user2'],
              :alias_type => 'user',
              :order      => 99,
            })}
            it { is_expected.to create_sudo__alias('host_alias').with({
              :content    => ['host1','host2'],
              :alias_type => 'host',
              :order      => 10, # default
            })}
          end
        end

        context 'should create sudo::include_dir resources with an iterator' do
          let(:hieradata) { 'sudo__include_dirs' }
          is { is_expected.to create_sudo__include_dir('/etc/sudoers.d')
          is { is_expected.to create_sudo__include_dir('/etc/simp_sudoers.d')
          }
        }
      end
    end
  end
end
