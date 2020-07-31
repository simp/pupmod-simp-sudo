require 'spec_helper'

describe 'sudo::user_specification' do
 context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts){ os_facts }

        let(:title) { 'user_specification_spec' }

        context 'default parameters' do
          let(:params) {{
            :user_list => ['joe','jimbob','%foo'],
            :cmnd      => ['ifconfig']
          }}

          it do
            is_expected.to create_concat__fragment("sudo_user_specification_#{title}")
              .with_content("joe, jimbob, %foo    #{facts[:hostname]}, #{facts[:fqdn]}=(root)  PASSWD:EXEC:SETENV: ifconfig\n")
          end
        end

        context 'passwd, doexec, and setenv all false' do
          let(:params) {{
            :user_list => ['joe','jimbob','%foo'],
            :cmnd      => ['ifconfig', 'tcpdump'],
            :passwd    => false,
            :doexec    => false,
            :setenv    => false
          }}

          it do
            is_expected.to create_concat__fragment("sudo_user_specification_#{title}")
              .with_content("joe, jimbob, %foo    #{facts[:hostname]}, #{facts[:fqdn]}=(root)  NOPASSWD:NOEXEC:NOSETENV: ifconfig, tcpdump\n")
          end
        end

        context 'with an empty host list' do
          let(:params) {{
            :user_list => ['joe','jimbob','%foo'],
            :cmnd      => ['ifconfig', 'tcpdump'],
            :hostlist  => []
          }}

          it do
            is_expected.to raise_error(Puppet::Error)
          end
        end

        context 'with role in options' do
          let(:params) {{
            :user_list => ['joe','jimbob','%foo'],
            :cmnd      => ['ifconfig', 'tcpdump'],
            :passwd    => false,
            :doexec    => false,
            :setenv    => false,
            :options   => {'role' => 'unconfined_r'}
          }}

          it do
            is_expected.to create_concat__fragment("sudo_user_specification_#{title}")
              .with_content("joe, jimbob, %foo    #{facts[:hostname]}, #{facts[:fqdn]}=(root) ROLE=unconfined_r NOPASSWD:NOEXEC:NOSETENV: ifconfig, tcpdump\n")
          end
        end
        #test for cve_2019-14287 mitigation
        context 'with  sudo version <  1.8.28' do
          let(:facts) {
            os_facts.merge({
              'sudo_version' => '1.8.10'
          })}
          let(:params) {{
            :user_list => ['joe'],
            :cmnd      => ['cat'],
            :runas     => 'ALL',
            :passwd    => false,
            :doexec    => false,
            :setenv    => false,
          }}
          it do
            is_expected.to create_concat__fragment("sudo_user_specification_#{title}")
              .with_content("joe    #{facts[:hostname]}, #{facts[:fqdn]}=(ALL, !#-1)  NOPASSWD:NOEXEC:NOSETENV: cat\n")
          end
        end
        context 'with  sudo version >  1.8.28' do
          let(:facts) {
            os_facts.merge({
              'sudo_version' => '1.8.30'
          })}
          let(:params) {{
            :user_list => ['joe'],
            :cmnd      => ['cat'],
            :runas     => 'ALL',
            :passwd    => false,
            :doexec    => false,
            :setenv    => false,
          }}
          it do
            is_expected.to create_concat__fragment("sudo_user_specification_#{title}")
              .with_content("joe    #{facts[:hostname]}, #{facts[:fqdn]}=(ALL)  NOPASSWD:NOEXEC:NOSETENV: cat\n")
          end
        end
      end
    end
  end
end
