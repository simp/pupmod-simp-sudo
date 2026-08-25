require 'spec_helper'

describe 'sudo::user_specification' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) { os_facts }

        let(:title) { 'user_specification_spec' }

        context 'default parameters' do
          let(:params) do
            {
              user_list: ['joe', 'jimbob', '%foo'],
              cmnd: ['ifconfig'],
            }
          end

          it do
            is_expected.to create_file("/etc/sudoers.d/0090_uspec_#{title}")
              .with_content("joe, jimbob, %foo    #{facts[:hostname]}, #{facts[:fqdn]}=(root)  PASSWD:EXEC:SETENV: ifconfig\n")
          end

          it 'validates the file with visudo before install' do
            is_expected.to create_file("/etc/sudoers.d/0090_uspec_#{title}")
              .with_validate_cmd('/usr/sbin/visudo -cf %')
          end

          it 'notifies the strict whole-config check' do
            is_expected.to create_file("/etc/sudoers.d/0090_uspec_#{title}")
              .that_notifies('Exec[visudo strict configuration check]')
            is_expected.to contain_exec('visudo strict configuration check').with(
              command: '/usr/sbin/visudo -csf /etc/sudoers',
              refreshonly: true,
            ).that_requires('Package[sudo]')
          end
        end

        context 'with validate => false' do
          let(:params) do
            {
              user_list: ['joe'],
              cmnd: ['ifconfig'],
              validate: false,
            }
          end

          it do
            is_expected.to create_file("/etc/sudoers.d/0090_uspec_#{title}")
              .without_validate_cmd
          end
        end

        context 'with validation disabled module-wide' do
          let(:hieradata) { 'sudo__no_validation' }
          let(:params) do
            {
              user_list: ['joe'],
              cmnd: ['ifconfig'],
            }
          end

          it do
            is_expected.to create_file("/etc/sudoers.d/0090_uspec_#{title}")
              .without_validate_cmd
          end
          it { is_expected.not_to contain_exec('visudo strict configuration check') }

          context 'with validate => true overriding sudo::validate' do
            let(:params) { super().merge(validate: true) }

            it do
              is_expected.to create_file("/etc/sudoers.d/0090_uspec_#{title}")
                .with_validate_cmd('/usr/sbin/visudo -cf %')
            end
          end
        end

        context 'passwd, doexec, and setenv all false' do
          let(:params) do
            {
              user_list: ['joe', 'jimbob', '%foo'],
              cmnd: ['ifconfig', 'tcpdump'],
              passwd: false,
              doexec: false,
              setenv: false,
            }
          end

          it do
            is_expected.to create_file("/etc/sudoers.d/0090_uspec_#{title}")
              .with_content("joe, jimbob, %foo    #{facts[:hostname]}, #{facts[:fqdn]}=(root)  NOPASSWD:NOEXEC:NOSETENV: ifconfig, tcpdump\n")
          end
        end

        context 'with an empty host list' do
          let(:params) do
            {
              user_list: ['joe', 'jimbob', '%foo'],
              cmnd: ['ifconfig', 'tcpdump'],
              hostlist: [],
            }
          end

          it do
            is_expected.to raise_error(Puppet::Error)
          end
        end

        context 'with role in options' do
          let(:params) do
            {
              user_list: ['joe', 'jimbob', '%foo'],
              cmnd: ['ifconfig', 'tcpdump'],
              passwd: false,
              doexec: false,
              setenv: false,
              options: { 'role' => 'unconfined_r' },
            }
          end

          it do
            is_expected.to create_file("/etc/sudoers.d/0090_uspec_#{title}")
              .with_content("joe, jimbob, %foo    #{facts[:hostname]}, #{facts[:fqdn]}=(root) ROLE=unconfined_r NOPASSWD:NOEXEC:NOSETENV: ifconfig, tcpdump\n")
          end
        end
        # test for cve_2019-14287 mitigation
        context 'with  sudo version <  1.8.28' do
          let(:facts) do
            os_facts.merge(
              'sudo_version' => '1.8.10',
            )
          end
          let(:params) do
            {
              user_list: ['joe'],
              cmnd: ['cat'],
              runas: 'ALL',
              passwd: false,
              doexec: false,
              setenv: false,
            }
          end

          it do
            is_expected.to create_file("/etc/sudoers.d/0090_uspec_#{title}")
              .with_content("joe    #{facts[:hostname]}, #{facts[:fqdn]}=(ALL, !#-1)  NOPASSWD:NOEXEC:NOSETENV: cat\n")
          end
        end
        context 'with  sudo version >  1.8.28' do
          let(:facts) do
            os_facts.merge(
              'sudo_version' => '1.8.30',
            )
          end
          let(:params) do
            {
              user_list: ['joe'],
              cmnd: ['cat'],
              runas: 'ALL',
              passwd: false,
              doexec: false,
              setenv: false,
            }
          end

          it do
            is_expected.to create_file("/etc/sudoers.d/0090_uspec_#{title}")
              .with_content("joe    #{facts[:hostname]}, #{facts[:fqdn]}=(ALL)  NOPASSWD:NOEXEC:NOSETENV: cat\n")
          end
        end
      end
    end
  end
end
