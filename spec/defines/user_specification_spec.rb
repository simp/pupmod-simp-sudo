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
              .with_content("\njoe, jimbob, %foo    #{facts[:hostname]}, #{facts[:fqdn]}=(root) PASSWD:EXEC:SETENV: ifconfig\n\n")
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
              .with_content("\njoe, jimbob, %foo    #{facts[:hostname]}, #{facts[:fqdn]}=(root) NOPASSWD:NOEXEC:NOSETENV: ifconfig, tcpdump\n\n")
          end
        end
      end
    end
  end
end
